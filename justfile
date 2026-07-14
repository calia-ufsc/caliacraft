set dotenv-load

DATA_DIR  := env_var_or_default("DATA_DIR", env_var('HOME') + "/data")
BIN_DIR   := env_var_or_default("BIN_DIR", env_var('HOME') + "/bin")
PAPER_VERSION := env_var_or_default("PAPER_VERSION", "26.2")
MC_RAM_MIN := env_var_or_default("MC_RAM_MIN", "2G")
MC_RAM_MAX := env_var_or_default("MC_RAM_MAX", "8G")

MINECRAFT_DIR := DATA_DIR + "/minecraft"
JAVA          := DATA_DIR + "/jdk/bin/java"

[private]
default:
    @just --list

# Bootstrap the environment (run once)
bootstrap:
    bash bootstrap.sh

# ── Minecraft ─────────────────────────────────────────────────────────────────

# Start the Minecraft server (foreground)
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

# Start Minecraft in background (tmux)
mc-up:
    tmux has-session -t minecraft 2>/dev/null && echo "already running" || \
      tmux new-session -d -s minecraft "cd {{MINECRAFT_DIR}} && just mc-start"
    @echo "Minecraft running — attach with: just mc-console"

# Stop Minecraft (graceful)
mc-down:
    -tmux send-keys -t minecraft "stop" Enter 2>/dev/null
    @echo "stop sent"

# Attach to Minecraft console
mc-console:
    tmux attach -t minecraft

# Show Minecraft status
mc-status:
    @tmux has-session -t minecraft 2>/dev/null && echo "running" || echo "stopped"

# ── Tunnel ────────────────────────────────────────────────────────────────────

# Start playit.gg tunnel (interactive — follow the claim URL)
tunnel-playit:
    mkdir -p ~/.config/playit_gg
    {{BIN_DIR}}/playit

# Start frpc tunnel (foreground)
tunnel-frp:
    frpc -c ~/.config/frp/frpc.toml

# Start frpc tunnel in background (tmux)
tunnel-frp-up:
    tmux has-session -t frpc 2>/dev/null && echo "already running" || \
      tmux new-session -d -s frpc "frpc -c ~/.config/frp/frpc.toml"
    @echo "frpc running in tmux session 'frpc'"

# Stop frpc tunnel
tunnel-frp-down:
    -pkill -f frpc 2>/dev/null
    -tmux kill-session -t frpc 2>/dev/null
    @echo "frpc stopped"

# ── Full stack ────────────────────────────────────────────────────────────────

# Start Minecraft in background, then prompt for tunnel
up:
    just mc-up
    @echo "Start tunnel with: just tunnel-playit  (or just tunnel-frp-up)"

# Stop everything
down:
    just mc-down
    just tunnel-frp-down

# Show status of all services
status:
    @echo "Minecraft : $(just mc-status)"
    @tmux has-session -t frpc 2>/dev/null && echo "frpc      : running" || echo "frpc      : stopped"
