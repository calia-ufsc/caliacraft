set dotenv-load

DATA_DIR      := env_var_or_default("DATA_DIR", env_var('HOME') + "/data")
BIN_DIR       := env_var_or_default("BIN_DIR", env_var('HOME') + "/bin")
PAPER_VERSION := env_var_or_default("PAPER_VERSION", "26.2")
MC_RAM_MIN    := env_var_or_default("MC_RAM_MIN", "2G")
MC_RAM_MAX    := env_var_or_default("MC_RAM_MAX", "8G")

MINECRAFT_DIR := DATA_DIR + "/minecraft"
JAVA          := DATA_DIR + "/jdk/bin/java"

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

# Start the Minecraft server in a background tmux session
mc-up:
    @tmux has-session -t minecraft 2>/dev/null \
      && echo "already running — attach with: just mc-console" \
      || (tmux new-session -d -s minecraft -c {{MINECRAFT_DIR}} \
            "just mc-start" \
          && echo "Minecraft started — attach with: just mc-console")

# Send a graceful stop to the Minecraft server
mc-down:
    @tmux has-session -t minecraft 2>/dev/null \
      && (tmux send-keys -t minecraft "stop" Enter && echo "stop sent") \
      || echo "server is not running"

# Attach to the Minecraft server console (detach with Ctrl+B D)
mc-console:
    tmux attach -t minecraft

# Show whether the Minecraft server is running
mc-status:
    @tmux has-session -t minecraft 2>/dev/null && echo "running" || echo "stopped"

# ── Tunnel ────────────────────────────────────────────────────────────────────

# Start the playit.gg tunnel interactively (follow the claim URL on first run)
tunnel-playit:
    mkdir -p ~/.config/playit_gg
    {{BIN_DIR}}/playit

# Start the frp tunnel in the foreground
tunnel-frp:
    frpc -c ~/.config/frp/frpc.toml

# Start the frp tunnel in a background tmux session
tunnel-frp-up:
    @tmux has-session -t frpc 2>/dev/null \
      && echo "already running — attach with: just tunnel-frp-console" \
      || (tmux new-session -d -s frpc "frpc -c ~/.config/frp/frpc.toml" \
          && echo "frpc started — attach with: just tunnel-frp-console")

# Stop the frp tunnel
tunnel-frp-down:
    @tmux has-session -t frpc 2>/dev/null \
      && (tmux kill-session -t frpc && echo "frpc stopped") \
      || echo "frpc is not running"

# Attach to the frp tunnel session (detach with Ctrl+B D)
tunnel-frp-console:
    tmux attach -t frpc

# ── Full stack ────────────────────────────────────────────────────────────────

# Start Minecraft in background and prompt for tunnel choice
up:
    just mc-up
    @echo ""
    @echo "Start a tunnel:"
    @echo "  just tunnel-playit    # playit.gg (interactive, follow the claim URL)"
    @echo "  just tunnel-frp-up    # frp (background, requires ~/.config/frp/frpc.toml)"

# Stop Minecraft and the frp tunnel
down:
    just mc-down
    just tunnel-frp-down

# Show status of all services
status:
    @echo "Minecraft : $(just mc-status)"
    @tmux has-session -t frpc 2>/dev/null && echo "frpc      : running" || echo "frpc      : stopped"
