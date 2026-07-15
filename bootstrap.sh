#!/usr/bin/env bash
set -euo pipefail

# Load .env if present
[ -f .env ] && set -a && source .env && set +a

DATA_DIR="${DATA_DIR:-$HOME/data}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"
NEOFORGE_VERSION="${NEOFORGE_VERSION:-21.1.228}"
MC_RAM_MIN="${MC_RAM_MIN:-2G}"
MC_RAM_MAX="${MC_RAM_MAX:-8G}"
MINECRAFT_DIR="$DATA_DIR/minecraft"

step() { echo; echo "── $1 ──────────────────────────────────────────────"; }
ok()   { echo "  ✓ $1"; }
info() { echo "  → $1"; }

mkdir -p "$BIN_DIR" "$MINECRAFT_DIR" "$DATA_DIR/run" "$HOME/.config/frp" "$HOME/.config/playit_gg"

# ── PATH ─────────────────────────────────────────────────────────────────────
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
export PATH="$BIN_DIR:$DATA_DIR/jdk/bin:$PATH"

# ── Java 21 ──────────────────────────────────────────────────────────────────
step "Java 21"
if [ ! -f "$DATA_DIR/jdk/bin/java" ]; then
  info "Downloading Zulu JDK 21..."
  curl -Lo /tmp/jdk.tar.gz \
    "https://cdn.azul.com/zulu/bin/zulu21.42.19-ca-jdk21.0.7-linux_x64.tar.gz"
  mkdir -p "$DATA_DIR/jdk"
  tar -xzf /tmp/jdk.tar.gz -C "$DATA_DIR/jdk" --strip-components=1
  rm /tmp/jdk.tar.gz
  ok "Java $($DATA_DIR/jdk/bin/java -version 2>&1 | head -1)"
else
  ok "Already installed: $($DATA_DIR/jdk/bin/java -version 2>&1 | head -1)"
fi

# ── just ─────────────────────────────────────────────────────────────────────
step "just"
if [ ! -f "$BIN_DIR/just" ]; then
  info "Downloading just 1.56.0..."
  curl -Lo /tmp/just.tar.gz \
    "https://github.com/casey/just/releases/download/1.56.0/just-1.56.0-x86_64-unknown-linux-musl.tar.gz"
  tar -xzf /tmp/just.tar.gz -C "$BIN_DIR" just
  rm /tmp/just.tar.gz
  ok "just $($BIN_DIR/just --version)"
else
  ok "Already installed: $(just --version)"
fi

# ── playit ───────────────────────────────────────────────────────────────────
step "playit"
if [ ! -f "$BIN_DIR/playit" ]; then
  info "Downloading playit v0.15.26..."
  curl -Lo "$BIN_DIR/playit" \
    "https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
  chmod +x "$BIN_DIR/playit"
  ok "playit installed"
else
  ok "Already installed"
fi

# ── frpc ─────────────────────────────────────────────────────────────────────
step "frpc"
if [ ! -f "$BIN_DIR/frpc" ]; then
  info "Downloading frp v0.70.0..."
  curl -Lo /tmp/frp.tar.gz \
    "https://github.com/fatedier/frp/releases/download/v0.70.0/frp_0.70.0_linux_amd64.tar.gz"
  tar -xzf /tmp/frp.tar.gz -C /tmp/
  cp /tmp/frp_0.70.0_linux_amd64/frpc "$BIN_DIR/"
  rm -rf /tmp/frp.tar.gz /tmp/frp_0.70.0_linux_amd64
  ok "frpc installed"
else
  ok "Already installed"
fi

# ── NeoForge ─────────────────────────────────────────────────────────────────
step "NeoForge $NEOFORGE_VERSION"
INSTALLER_JAR="$MINECRAFT_DIR/neoforge-${NEOFORGE_VERSION}-installer.jar"
if [ ! -f "$MINECRAFT_DIR/run.sh" ]; then
  if [ ! -f "$INSTALLER_JAR" ]; then
    info "Downloading NeoForge installer..."
    curl -Lo "$INSTALLER_JAR" \
      "https://maven.neoforged.net/releases/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-installer.jar"
  fi
  info "Running NeoForge installer (this may take a few minutes)..."
  cd "$MINECRAFT_DIR"
  "$DATA_DIR/jdk/bin/java" -jar "$INSTALLER_JAR" --installServer
  rm -f "$INSTALLER_JAR"
  cd - > /dev/null
  ok "NeoForge installed"
else
  ok "Already installed"
fi

# ── Minecraft config ─────────────────────────────────────────────────────────
step "Minecraft config"
if [ ! -f "$MINECRAFT_DIR/eula.txt" ]; then
  echo "eula=true" > "$MINECRAFT_DIR/eula.txt"
  ok "eula.txt created"
else
  ok "eula.txt already exists"
fi

if [ ! -f "$MINECRAFT_DIR/server.properties" ]; then
  cat > "$MINECRAFT_DIR/server.properties" << 'EOF'
online-mode=false
view-distance=6
simulation-distance=4
EOF
  ok "server.properties created"
else
  ok "server.properties already exists"
fi

# NeoForge reads JVM args from user_jvm_args.txt
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
  ok "user_jvm_args.txt created"
else
  ok "user_jvm_args.txt already exists"
fi

# ── frpc config template ─────────────────────────────────────────────────────
step "frpc config"
if [ ! -f "$HOME/.config/frp/frpc.toml" ]; then
  cat > "$HOME/.config/frp/frpc.toml" << 'EOF'
# Fill in serverAddr and auth.token before using frp tunnel
serverAddr = ""
serverPort = 8443

auth.method = "token"
auth.token = ""

[transport]
tls.enable = true

[[proxies]]
name = "minecraft"
type = "tcp"
localIP = "127.0.0.1"
localPort = 25565
remotePort = 25565
EOF
  ok "Template created at ~/.config/frp/frpc.toml — fill in serverAddr and auth.token"
else
  ok "Config already exists"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo
echo "Bootstrap complete. Run 'just' to see available commands."
