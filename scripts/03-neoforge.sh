#!/usr/bin/env bash
# Download and install NeoForge into $MINECRAFT_DIR (generates run.sh and libraries/)
set -euo pipefail
source "$(dirname "$0")/_env.sh"

if [ -f "$MINECRAFT_DIR/run.sh" ]; then
  ok "NeoForge $NEOFORGE_VERSION already installed"
  exit 0
fi

INSTALLER_JAR="$MINECRAFT_DIR/neoforge-${NEOFORGE_VERSION}-installer.jar"

if [ ! -f "$INSTALLER_JAR" ]; then
  info "Downloading NeoForge $NEOFORGE_VERSION installer"
  curl -Lo "$INSTALLER_JAR" \
    "https://maven.neoforged.net/releases/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-installer.jar"
fi

info "Running NeoForge installer (downloads Minecraft libraries — takes a few minutes)"
cd "$MINECRAFT_DIR"
"$DATA_DIR/jdk/bin/java" -jar "$INSTALLER_JAR" --installServer
rm -f "$INSTALLER_JAR"
cd - > /dev/null

ok "NeoForge $NEOFORGE_VERSION installed"
