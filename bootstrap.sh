#!/usr/bin/env bash
# Provisions the caliacraft Minecraft server.
# Requires vlab tools (Java, just, frpc) — run the vlab bootstrap first.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT_DIR/scripts/_env.sh"

step() { echo; echo "── $1 ──────────────────────────────────────────────"; }
ok()   { echo "  ✓ $1"; }
info() { echo "  → $1"; }

# ── Check vlab dependency ─────────────────────────────────────────────────────
if [ ! -f "$DATA_DIR/jdk/bin/java" ] || [ ! -f "$BIN_DIR/frpc" ]; then
  echo "error: vlab tools not provisioned."
  echo "  Run bootstrap.sh in the vlab provisioning repo first."
  exit 1
fi

# ── envow validate ────────────────────────────────────────────────────────────
step "Validating environment"
if command -v envow &>/dev/null; then
  envow validate "$ROOT_DIR/envow.toml"
  ok "Environment valid"
else
  info "envow not found — skipping validation"
fi

# ── Steps ─────────────────────────────────────────────────────────────────────
step "01 · NeoForge $NEOFORGE_VERSION"
bash "$ROOT_DIR/scripts/01-neoforge.sh"

step "02 · Mods"
bash "$ROOT_DIR/scripts/02-mods.sh"

step "03 · Server-side extras (FTB Backups 2)"
bash "$ROOT_DIR/scripts/03-extras.sh"

step "04 · Server config"
bash "$ROOT_DIR/scripts/04-config.sh"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo "Bootstrap complete. Run 'just' to see available commands."
