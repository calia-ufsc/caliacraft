set dotenv-load

PRIVADO := env_var('HOME') + "/privado"
MINECRAFT_DIR := PRIVADO + "/minecraft"
JAVA := PRIVADO + "/jdk25/bin/java"
PAPER_VERSION := "26.2"

[private]
default:
    @just --list

# Bootstrap the vlab environment (run once)
bootstrap:
    bash bootstrap.sh

# ── Minecraft ─────────────────────────────────────────────────────────────────

# Start the Minecraft server
mc-start:
    cd {{MINECRAFT_DIR}} && {{JAVA}} -Xms2G -Xmx8G \
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
    @echo "Minecraft running in tmux session 'minecraft'"

# Stop Minecraft (graceful)
mc-down:
    tmux send-keys -t minecraft "stop" Enter 2>/dev/null || true
    @echo "stop sent"

# Attach to Minecraft console
mc-console:
    tmux attach -t minecraft

# Show Minecraft server status
mc-status:
    @tmux has-session -t minecraft 2>/dev/null && echo "running" || echo "stopped"

# ── Tunnel ────────────────────────────────────────────────────────────────────

# Start playit.gg tunnel
tunnel-playit:
    mkdir -p ~/.config/playit_gg
    ~/bin/playit

# Start frpc tunnel
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

# Start Minecraft + playit tunnel
up:
    just mc-up
    @echo "Start tunnel with: just tunnel-playit"

# Stop everything
down:
    just mc-down
    just tunnel-frp-down

# Show status of all services
status:
    @echo "Minecraft: $(just mc-status)"
    @tmux has-session -t frpc 2>/dev/null && echo "frpc: running" || echo "frpc: stopped"
