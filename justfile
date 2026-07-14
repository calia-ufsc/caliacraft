set dotenv-load

DATA_DIR      := env_var_or_default("DATA_DIR", env_var('HOME') + "/data")
BIN_DIR       := env_var_or_default("BIN_DIR", env_var('HOME') + "/bin")
PAPER_VERSION := env_var_or_default("PAPER_VERSION", "26.2")
MC_RAM_MIN    := env_var_or_default("MC_RAM_MIN", "2G")
MC_RAM_MAX    := env_var_or_default("MC_RAM_MAX", "8G")

MINECRAFT_DIR := DATA_DIR + "/minecraft"
JAVA          := DATA_DIR + "/jdk/bin/java"
RUN_DIR       := DATA_DIR + "/run"

[private]
default:
    @just --list

# ── Setup ─────────────────────────────────────────────────────────────────────

# Install all dependencies and configure the environment (run once)
bootstrap:
    bash bootstrap.sh

# ── Minecraft ─────────────────────────────────────────────────────────────────

# Start the Minecraft server in the foreground (useful for debugging)
mc-start:
    cd {{MINECRAFT_DIR}} && {{JAVA}} -Xms{{MC_RAM_MIN}} -Xmx{{MC_RAM_MAX}} \
      -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
      -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC \
      -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 \
      -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \
      -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 \
      -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 \
      -XX:G1MixedGCLiveThresholdPercent=90 \
      -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 \
      -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \
      -jar paper-{{PAPER_VERSION}}.jar nogui

# Start the Minecraft server in the background (nohup)
mc-up:
    #!/usr/bin/env bash
    mkdir -p {{RUN_DIR}}
    PID_FILE={{RUN_DIR}}/minecraft.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "already running (pid $(cat "$PID_FILE"))"
      exit 0
    fi
    cd {{MINECRAFT_DIR}}
    nohup {{JAVA}} -Xms{{MC_RAM_MIN}} -Xmx{{MC_RAM_MAX}} \
      -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
      -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC \
      -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 \
      -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \
      -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 \
      -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 \
      -XX:G1MixedGCLiveThresholdPercent=90 \
      -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 \
      -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \
      -jar paper-{{PAPER_VERSION}}.jar nogui \
      > {{RUN_DIR}}/minecraft.log 2>&1 &
    echo $! > "$PID_FILE"
    echo "Minecraft started (pid $!) — logs: just mc-logs"

# Send a graceful stop to the Minecraft server
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

# ── Tunnel ────────────────────────────────────────────────────────────────────

# Start the playit.gg tunnel in the background (nohup)
tunnel-playit:
    #!/usr/bin/env bash
    mkdir -p {{RUN_DIR}} ~/.config/playit_gg
    PID_FILE={{RUN_DIR}}/playit.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "already running (pid $(cat "$PID_FILE"))"
      exit 0
    fi
    nohup {{BIN_DIR}}/playit > {{RUN_DIR}}/playit.log 2>&1 &
    echo $! > "$PID_FILE"
    echo "playit started (pid $!) — logs: just tunnel-playit-logs"

# Tail the playit tunnel log
tunnel-playit-logs:
    tail -f {{RUN_DIR}}/playit.log

# Stop the playit tunnel
tunnel-playit-down:
    #!/usr/bin/env bash
    PID_FILE={{RUN_DIR}}/playit.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      kill "$(cat "$PID_FILE")" && rm "$PID_FILE" && echo "playit stopped"
    else
      echo "playit is not running"
    fi

FRP_CONFIG := justfile_directory() + "/config/frpc.toml"

# Start the frp tunnel in the foreground
tunnel-frp:
    {{BIN_DIR}}/frpc -c {{FRP_CONFIG}}

# Start the frp tunnel in the background (nohup)
tunnel-frp-up:
    #!/usr/bin/env bash
    mkdir -p {{RUN_DIR}}
    PID_FILE={{RUN_DIR}}/frpc.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "already running (pid $(cat "$PID_FILE"))"
      exit 0
    fi
    nohup {{BIN_DIR}}/frpc -c {{FRP_CONFIG}} > {{RUN_DIR}}/frpc.log 2>&1 &
    echo $! > "$PID_FILE"
    echo "frpc started (pid $!) — logs: just tunnel-frp-logs"

# Stop the frp tunnel
tunnel-frp-down:
    #!/usr/bin/env bash
    PID_FILE={{RUN_DIR}}/frpc.pid
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      kill "$(cat "$PID_FILE")" && rm "$PID_FILE" && echo "frpc stopped"
    else
      echo "frpc is not running"
    fi

# Tail the frp tunnel log
tunnel-frp-logs:
    tail -f {{RUN_DIR}}/frpc.log

# ── Full stack ────────────────────────────────────────────────────────────────

# Start Minecraft in background and prompt for tunnel choice
up:
    just mc-up
    @echo ""
    @echo "Start a tunnel:"
    @echo "  just tunnel-playit    # playit.gg (background)"
    @echo "  just tunnel-frp-up    # frp (background, requires ~/.config/frp/frpc.toml)"

# Stop Minecraft and all tunnels
down:
    just mc-down
    just tunnel-frp-down
    just tunnel-playit-down

# Show status of all services
status:
    #!/usr/bin/env bash
    mc_pid={{RUN_DIR}}/minecraft.pid
    playit_pid={{RUN_DIR}}/playit.pid
    frpc_pid={{RUN_DIR}}/frpc.pid
    [ -f "$mc_pid" ]     && kill -0 "$(cat "$mc_pid")"     2>/dev/null && echo "Minecraft : running (pid $(cat "$mc_pid"))"     || echo "Minecraft : stopped"
    [ -f "$playit_pid" ] && kill -0 "$(cat "$playit_pid")" 2>/dev/null && echo "playit    : running (pid $(cat "$playit_pid"))" || echo "playit    : stopped"
    [ -f "$frpc_pid" ]   && kill -0 "$(cat "$frpc_pid")"   2>/dev/null && echo "frpc      : running (pid $(cat "$frpc_pid"))"   || echo "frpc      : stopped"
