#!/usr/bin/env bash
# Write eula.txt, server.properties, and user_jvm_args.txt
# Safe to re-run — only creates files that don't exist yet
set -euo pipefail
source "$(dirname "$0")/_env.sh"

# eula
if [ ! -f "$MINECRAFT_DIR/eula.txt" ]; then
  echo "eula=true" > "$MINECRAFT_DIR/eula.txt"
  ok "eula.txt created"
else
  ok "eula.txt already exists"
fi

# server.properties — only the settings we care about; Minecraft fills in the rest on first run
if [ ! -f "$MINECRAFT_DIR/server.properties" ]; then
  cat > "$MINECRAFT_DIR/server.properties" << 'EOF'
online-mode=false
difficulty=normal
spawn-protection=0
enforce-secure-profile=false
view-distance=6
simulation-distance=4
EOF
  ok "server.properties created"
else
  ok "server.properties already exists"
fi

# JVM heap flags — NeoForge reads these from user_jvm_args.txt, NOT from the command line
if [ ! -f "$MINECRAFT_DIR/user_jvm_args.txt" ]; then
  cat > "$MINECRAFT_DIR/user_jvm_args.txt" << EOF
-Xms${MC_RAM_MIN}
-Xmx${MC_RAM_MAX}
-XX:+UseG1GC
-XX:+ParallelRefProcEnabled
-XX:MaxGCPauseMillis=200
-XX:+UnlockExperimentalVMOptions
-XX:+DisableExplicitGC
-XX:+AlwaysPreTouch
-XX:G1NewSizePercent=30
-XX:G1MaxNewSizePercent=40
-XX:G1HeapRegionSize=8M
-XX:G1ReservePercent=20
-XX:G1HeapWastePercent=5
-XX:G1MixedGCCountTarget=4
-XX:InitiatingHeapOccupancyPercent=15
-XX:G1MixedGCLiveThresholdPercent=90
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:SurvivorRatio=32
-XX:+PerfDisableSharedMem
-XX:MaxTenuringThreshold=1
EOF
  ok "user_jvm_args.txt created (${MC_RAM_MIN}–${MC_RAM_MAX})"
else
  ok "user_jvm_args.txt already exists"
fi
