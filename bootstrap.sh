#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

step() { echo; echo "── $1 ──────────────────────────────────────────────"; }
ok()   { echo "  ✓ $1"; }
info() { echo "  → $1"; }

# ── envow validate ────────────────────────────────────────────────────────────
step "Validating environment"
if command -v envow &>/dev/null; then
  envow validate "$ROOT_DIR/envow.toml"
  ok "Environment valid"
else
  info "envow not found — skipping validation (install: cargo install --git https://github.com/mb4ndeira/envow)"
fi

# ── PATH setup ────────────────────────────────────────────────────────────────
source "$ROOT_DIR/scripts/_env.sh"
step "PATH"
if ! grep -q 'caliacraft' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" << EOF

# caliacraft
export PATH="$BIN_DIR:$DATA_DIR/jdk/bin:\$PATH"
EOF
  ok ".bashrc updated"
else
  ok ".bashrc already configured"
fi

# ── Steps ─────────────────────────────────────────────────────────────────────
step "01 · Java 21"
bash "$ROOT_DIR/scripts/01-java.sh"

step "02 · Tools (just, playit, frpc)"
bash "$ROOT_DIR/scripts/02-tools.sh"

step "03 · NeoForge $NEOFORGE_VERSION"
bash "$ROOT_DIR/scripts/03-neoforge.sh"

step "04 · Mods"
bash "$ROOT_DIR/scripts/04-mods.sh"

step "05 · Server-side extras (backups, utilities)"
bash "$ROOT_DIR/scripts/05-extras.sh"

step "06 · Server config"
bash "$ROOT_DIR/scripts/06-config.sh"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo "Bootstrap complete. Run 'just' to see available commands."
