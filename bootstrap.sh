#!/usr/bin/env bash
set -euo pipefail

# Load .env if present
[ -f .env ] && set -a && source .env && set +a

DATA_DIR="${DATA_DIR:-$HOME/data}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"
PAPER_VERSION="${PAPER_VERSION:-26.2}"
MINECRAFT_DIR="$DATA_DIR/minecraft"

mkdir -p "$BIN_DIR" "$MINECRAFT_DIR"

# PATH setup
if ! grep -q 'caliacraft' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" << EOF

# caliacraft
export PATH="$BIN_DIR:$DATA_DIR/jdk/bin:\$PATH"
EOF
fi
export PATH="$BIN_DIR:$PATH"

# ── Java 25 ──────────────────────────────────────────────────────────────────
if [ ! -f "$DATA_DIR/jdk/bin/java" ]; then
  echo "Installing Java 25..."
  curl -Lo /tmp/jdk.tar.gz \
    "https://cdn.azul.com/zulu/bin/zulu25.34.17-ca-crac-jdk25.0.3-linux_x64.tar.gz"
  mkdir -p "$DATA_DIR/jdk"
  tar -xzf /tmp/jdk.tar.gz -C "$DATA_DIR/jdk" --strip-components=1
  rm /tmp/jdk.tar.gz
  echo "Java 25 installed"
else
  echo "Java 25 already installed"
fi

export JAVA_HOME="$DATA_DIR/jdk"
export PATH="$JAVA_HOME/bin:$PATH"

# ── playit ───────────────────────────────────────────────────────────────────
if [ ! -f "$BIN_DIR/playit" ]; then
  echo "Installing playit..."
  curl -Lo "$BIN_DIR/playit" \
    "https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
  chmod +x "$BIN_DIR/playit"
  echo "playit installed"
else
  echo "playit already installed"
fi

# ── frpc ─────────────────────────────────────────────────────────────────────
if [ ! -f "$BIN_DIR/frpc" ]; then
  echo "Installing frpc..."
  curl -Lo /tmp/frp.tar.gz \
    "https://github.com/fatedier/frp/releases/download/v0.70.0/frp_0.70.0_linux_amd64.tar.gz"
  tar -xzf /tmp/frp.tar.gz -C /tmp/
  cp /tmp/frp_0.70.0_linux_amd64/frpc "$BIN_DIR/"
  rm -rf /tmp/frp.tar.gz /tmp/frp_0.70.0_linux_amd64
  echo "frpc installed"
else
  echo "frpc already installed"
fi

# ── PaperMC ──────────────────────────────────────────────────────────────────
PAPER_JAR="$MINECRAFT_DIR/paper-${PAPER_VERSION}.jar"

if [ ! -f "$PAPER_JAR" ]; then
  echo "Downloading PaperMC $PAPER_VERSION..."
  PAPER_URL=$(curl -s -H "User-Agent: caliacraft/1.0" \
    "https://fill.papermc.io/v3/projects/paper/versions/${PAPER_VERSION}/builds" \
    | python3 -c "import sys,json; builds=json.load(sys.stdin); b=builds[-1]; print(b['downloads']['server:default']['url'])")
  curl -Lo "$PAPER_JAR" -H "User-Agent: caliacraft/1.0" "$PAPER_URL"
  echo "PaperMC downloaded"
else
  echo "PaperMC already downloaded"
fi

# ── eula & server.properties ─────────────────────────────────────────────────
[ ! -f "$MINECRAFT_DIR/eula.txt" ] && echo "eula=true" > "$MINECRAFT_DIR/eula.txt"

if [ ! -f "$MINECRAFT_DIR/server.properties" ]; then
  cat > "$MINECRAFT_DIR/server.properties" << 'EOF'
online-mode=false
view-distance=6
simulation-distance=4
EOF
fi

# ── frpc config template ─────────────────────────────────────────────────────
mkdir -p "$HOME/.config/frp"
if [ ! -f "$HOME/.config/frp/frpc.toml" ]; then
  cat > "$HOME/.config/frp/frpc.toml" << 'EOF'
# Fill in serverAddr and auth.token
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
  echo "frpc config template created at ~/.config/frp/frpc.toml"
fi

echo ""
echo "Bootstrap complete. Run 'just' to see available commands."
