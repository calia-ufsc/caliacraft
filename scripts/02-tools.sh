#!/usr/bin/env bash
# Install just, playit, and frpc into $BIN_DIR (no root needed)
set -euo pipefail
source "$(dirname "$0")/_env.sh"

# just (task runner)
if [ ! -f "$BIN_DIR/just" ]; then
  info "Downloading just $JUST_VERSION"
  curl -Lo /tmp/just.tar.gz \
    "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  tar -xzf /tmp/just.tar.gz -C "$BIN_DIR" just
  rm /tmp/just.tar.gz
  ok "just installed: $($BIN_DIR/just --version)"
else
  ok "just already installed: $($BIN_DIR/just --version)"
fi

# playit (tunnel — free, no VPS needed)
if [ ! -f "$BIN_DIR/playit" ]; then
  info "Downloading playit $PLAYIT_VERSION"
  curl -Lo "$BIN_DIR/playit" \
    "https://github.com/playit-cloud/playit-agent/releases/download/v${PLAYIT_VERSION}/playit-linux-amd64"
  chmod +x "$BIN_DIR/playit"
  ok "playit installed"
else
  ok "playit already installed"
fi

# frpc (tunnel — self-hosted, requires a VPS running frps)
if [ ! -f "$BIN_DIR/frpc" ]; then
  info "Downloading frp $FRP_VERSION"
  curl -Lo /tmp/frp.tar.gz \
    "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz"
  tar -xzf /tmp/frp.tar.gz -C /tmp/
  cp "/tmp/frp_${FRP_VERSION}_linux_amd64/frpc" "$BIN_DIR/"
  rm -rf /tmp/frp.tar.gz "/tmp/frp_${FRP_VERSION}_linux_amd64"
  ok "frpc installed"
else
  ok "frpc already installed"
fi
