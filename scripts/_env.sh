#!/usr/bin/env bash
# Sourced by every script — loads .env and exports all vars with defaults

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

[ -f "$ROOT_DIR/.env" ] && set -a && source "$ROOT_DIR/.env" && set +a

DATA_DIR="${DATA_DIR:-$HOME/data}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"
JAVA_URL="${JAVA_URL:-https://cdn.azul.com/zulu/bin/zulu21.42.19-ca-jdk21.0.7-linux_x64.tar.gz}"
JUST_VERSION="${JUST_VERSION:-1.56.0}"
PLAYIT_VERSION="${PLAYIT_VERSION:-0.15.26}"
FRP_VERSION="${FRP_VERSION:-0.70.0}"
NEOFORGE_VERSION="${NEOFORGE_VERSION:-21.1.233}"
MC_RAM_MIN="${MC_RAM_MIN:-4G}"
MC_RAM_MAX="${MC_RAM_MAX:-12G}"
SERVER_PACK_URL="${SERVER_PACK_URL:-}"

MINECRAFT_DIR="$DATA_DIR/minecraft"
export DATA_DIR BIN_DIR JAVA_URL JUST_VERSION PLAYIT_VERSION FRP_VERSION \
       NEOFORGE_VERSION MC_RAM_MIN MC_RAM_MAX SERVER_PACK_URL MINECRAFT_DIR

mkdir -p "$BIN_DIR" "$MINECRAFT_DIR" "$DATA_DIR/run"

# PATH
export PATH="$BIN_DIR:$DATA_DIR/jdk/bin:$PATH"

step() { echo; echo "── $1 ──────────────────────────────────────────────"; }
ok()   { echo "  ✓ $1"; }
info() { echo "  → $1"; }
