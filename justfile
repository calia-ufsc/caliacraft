set dotenv-load

DATA_DIR         := env_var_or_default("DATA_DIR", env_var('HOME') + "/data")
BIN_DIR          := env_var_or_default("BIN_DIR", env_var('HOME') + "/bin")
NEOFORGE_VERSION := env_var_or_default("NEOFORGE_VERSION", "21.1.233")

MINECRAFT_DIR := DATA_DIR + "/minecraft"
RUN_DIR       := DATA_DIR + "/run"

[private]
default:
    @just --list

# ── Dependency check ──────────────────────────────────────────────────────────

[private]
_check-vlab:
    #!/usr/bin/env bash
    missing=""
    [ ! -f "{{DATA_DIR}}/jdk/bin/java" ] && missing="$missing java"
    [ ! -f "{{BIN_DIR}}/frpc" ]          && missing="$missing frpc"
    [ ! -f "{{BIN_DIR}}/just" ]          && missing="$missing just"
    if [ -n "$missing" ]; then
      echo "error: vlab tools not provisioned:$missing"
      echo "  Run bootstrap.sh in the vlab provisioning repo first."
      exit 1
    fi

# ── Setup ─────────────────────────────────────────────────────────────────────

# Install NeoForge, mods, and server config (run once — requires vlab bootstrap)
bootstrap: _check-vlab
    bash bootstrap.sh

# ── Minecraft ─────────────────────────────────────────────────────────────────

# Start the Minecraft server in the foreground (useful for debugging)
mc-start: _check-vlab
    cd {{MINECRAFT_DIR}} && bash run.sh

# Start the Minecraft server in the background (nohup)
mc-up: _check-vlab
    #!/usr/bin/env bash
    mkdir -p {{RUN_DIR}}
    PID_FILE={{RUN_DIR}}/minecraft.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "already running (pid $(cat "$PID_FILE"))"
      exit 0
    fi
    cd {{MINECRAFT_DIR}}
    nohup bash run.sh > {{RUN_DIR}}/minecraft.log 2>&1 &
    echo $! > "$PID_FILE"
    echo "Minecraft started (pid $!) — logs: just mc-logs"

# Stop the Minecraft server
mc-down:
    #!/usr/bin/env bash
    PID_FILE={{RUN_DIR}}/minecraft.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      kill "$(cat "$PID_FILE")" && rm "$PID_FILE" && echo "stopped"
    else
      echo "server is not running"
    fi

# Tail the Minecraft server log
mc-logs:
    tail -f {{RUN_DIR}}/minecraft.log

# Show whether the Minecraft server is running
mc-status:
    #!/usr/bin/env bash
    PID_FILE={{RUN_DIR}}/minecraft.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "running (pid $(cat "$PID_FILE"))"
    else
      echo "stopped"
    fi

# Temporarily move mods aside and start in vanilla mode
mc-vanilla:
    #!/usr/bin/env bash
    if [ -d {{MINECRAFT_DIR}}/mods ]; then
      mv {{MINECRAFT_DIR}}/mods {{MINECRAFT_DIR}}/mods.disabled
      echo "mods disabled — starting vanilla"
    fi
    cd {{MINECRAFT_DIR}} && bash run.sh

# Restore mods folder after a vanilla run
mc-restore-mods:
    #!/usr/bin/env bash
    if [ -d {{MINECRAFT_DIR}}/mods.disabled ]; then
      mv {{MINECRAFT_DIR}}/mods.disabled {{MINECRAFT_DIR}}/mods
      echo "mods restored"
    else
      echo "nothing to restore"
    fi

# ── Backups ───────────────────────────────────────────────────────────────────

# Create a timestamped tar of the world folders
backup:
    #!/usr/bin/env bash
    BACKUP_DIR={{DATA_DIR}}/backups
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ARCHIVE="$BACKUP_DIR/world_${TIMESTAMP}.tar.gz"
    echo "Creating backup: $ARCHIVE"
    tar -czf "$ARCHIVE" -C {{MINECRAFT_DIR}} world world_nether world_the_end 2>/dev/null || true
    echo "Done: $(du -sh "$ARCHIVE" | cut -f1)"

# Sync backups folder to R2
backup-sync:
    #!/usr/bin/env bash
    source {{justfile_directory()}}/scripts/_env.sh
    if [ -z "${R2_BUCKET:-}" ] || [ -z "${R2_ENDPOINT:-}" ]; then
      echo "error: R2_BUCKET and R2_ENDPOINT must be set in .env"
      exit 1
    fi
    {{BIN_DIR}}/rclone sync {{DATA_DIR}}/backups/ r2:${R2_BUCKET}/caliacraft/ --progress

# Run backup + sync in a loop every hour (nohup)
backup-loop:
    #!/usr/bin/env bash
    mkdir -p {{RUN_DIR}}
    PID_FILE={{RUN_DIR}}/backup.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "already running (pid $(cat "$PID_FILE"))"
      exit 0
    fi
    nohup bash -c 'while true; do
      cd {{justfile_directory()}} && just backup && just backup-sync
      sleep 3600
    done' > {{RUN_DIR}}/backup.log 2>&1 &
    echo $! > "$PID_FILE"
    echo "backup loop started (pid $!) — logs: just backup-logs"

# Stop the backup loop
backup-loop-down:
    #!/usr/bin/env bash
    PID_FILE={{RUN_DIR}}/backup.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      kill "$(cat "$PID_FILE")" && rm "$PID_FILE" && echo "backup loop stopped"
    else
      echo "backup loop is not running"
    fi

# Tail the backup log
backup-logs:
    tail -f {{RUN_DIR}}/backup.log

# ── Status ────────────────────────────────────────────────────────────────────

# Show status of all caliacraft services
status:
    #!/usr/bin/env bash
    mc_pid={{RUN_DIR}}/minecraft.pid
    [ -f "$mc_pid" ] && kill -0 "$(cat "$mc_pid")" 2>/dev/null \
      && echo "Minecraft: running (pid $(cat "$mc_pid"))" \
      || echo "Minecraft: stopped"
