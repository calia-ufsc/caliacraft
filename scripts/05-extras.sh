#!/usr/bin/env bash
# Install server-side utility mods that run regardless of the modpack
# (backups, monitoring, etc.) — safe to run with vanilla NeoForge too
set -euo pipefail
source "$(dirname "$0")/_env.sh"

MODS_DIR="$MINECRAFT_DIR/mods"
mkdir -p "$MODS_DIR"

# FTB Backups 2 — rolling compressed world backups from inside the server process
FTB_BACKUPS_JAR="$MODS_DIR/ftbbackups2-neoforge-1.0.28.jar"
FTB_BACKUPS_URL="https://www.curseforge.com/api/v1/mods/666401/files/5501351/download"

if [ ! -f "$FTB_BACKUPS_JAR" ]; then
  info "Downloading FTB Backups 2 (server-side only)"
  curl -Lo "$FTB_BACKUPS_JAR" "$FTB_BACKUPS_URL"
  ok "FTB Backups 2 installed"
else
  ok "FTB Backups 2 already installed"
fi
