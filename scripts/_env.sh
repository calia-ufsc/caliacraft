#!/usr/bin/env bash
# Sourced by every caliacraft script — loads .env and exports minecraft vars

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

[ -f "$ROOT_DIR/.env" ] && set -a && source "$ROOT_DIR/.env" && set +a

DATA_DIR="${DATA_DIR:-$HOME/data}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"
NEOFORGE_VERSION="${NEOFORGE_VERSION:-21.1.233}"
MC_RAM_MIN="${MC_RAM_MIN:-4G}"
MC_RAM_MAX="${MC_RAM_MAX:-12G}"
SERVER_PACK_URL="${SERVER_PACK_URL:-}"
_CORES="$(nproc 2>/dev/null || echo 4)"
MC_GC_THREADS="${MC_GC_THREADS:-$(( _CORES / 4 < 16 ? _CORES / 4 : 16 ))}"
unset _CORES
MC_VIEW_DISTANCE="${MC_VIEW_DISTANCE:-6}"
MC_SIMULATION_DISTANCE="${MC_SIMULATION_DISTANCE:-4}"
MC_DIFFICULTY="${MC_DIFFICULTY:-normal}"
MC_MOTD="${MC_MOTD:-🎲 caliacraft}"
MC_MAX_PLAYERS="${MC_MAX_PLAYERS:-20}"
MC_ONLINE_MODE="${MC_ONLINE_MODE:-false}"
MC_SPAWN_PROTECTION="${MC_SPAWN_PROTECTION:-0}"
MC_ENFORCE_SECURE_PROFILE="${MC_ENFORCE_SECURE_PROFILE:-false}"

R2_ENDPOINT="${R2_ENDPOINT:-}"
R2_ACCESS_KEY="${R2_ACCESS_KEY:-}"
R2_SECRET_KEY="${R2_SECRET_KEY:-}"
R2_BUCKET="${R2_BUCKET:-}"

# rclone remote config via env vars — no config file needed
export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
export RCLONE_CONFIG_R2_ACL=private

MINECRAFT_DIR="$DATA_DIR/minecraft"
export DATA_DIR BIN_DIR NEOFORGE_VERSION MC_RAM_MIN MC_RAM_MAX MC_GC_THREADS \
       R2_ENDPOINT R2_ACCESS_KEY R2_SECRET_KEY R2_BUCKET \
       SERVER_PACK_URL MC_VIEW_DISTANCE MC_SIMULATION_DISTANCE MC_DIFFICULTY \
       MC_MOTD MC_MAX_PLAYERS MC_ONLINE_MODE MC_SPAWN_PROTECTION \
       MC_ENFORCE_SECURE_PROFILE MINECRAFT_DIR

mkdir -p "$MINECRAFT_DIR" "$DATA_DIR/run"
export PATH="$BIN_DIR:$DATA_DIR/jdk/bin:$PATH"

step() { echo; echo "── $1 ──────────────────────────────────────────────"; }
ok()   { echo "  ✓ $1"; }
info() { echo "  → $1"; }
