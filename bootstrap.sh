#!/usr/bin/env bash
set -euo pipefail

PRIVADO="$HOME/privado"
BIN="$HOME/bin"
MINECRAFT_DIR="$PRIVADO/minecraft"

mkdir -p "$BIN" "$MINECRAFT_DIR"

# PATH setup
if ! grep -q 'vlab' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" << 'EOF'

# vlab
export PATH="$HOME/bin:$HOME/privado/jdk25/bin:$PATH"
EOF
fi
export PATH="$BIN:$PATH"

# ── Java 25 ──────────────────────────────────────────────────────────────────
if [ ! -f "$PRIVADO/jdk25/bin/java" ]; then
  echo "Installing Java 25..."
  curl -Lo /tmp/jdk25.tar.gz \
    "https://cdn.azul.com/zulu/bin/zulu25.34.17-ca-crac-jdk25.0.3-linux_x64.tar.gz"
  mkdir -p "$PRIVADO/jdk25"
  tar -xzf /tmp/jdk25.tar.gz -C "$PRIVADO/jdk25" --strip-components=1
  rm /tmp/jdk25.tar.gz
  echo "Java 25 installed: $($PRIVADO/jdk25/bin/java -version 2>&1 | head -1)"
else
  echo "Java 25 already installed"
fi

export JAVA_HOME="$PRIVADO/jdk25"
export PATH="$JAVA_HOME/bin:$PATH"

# ── frpc ─────────────────────────────────────────────────────────────────────
if [ ! -f "$BIN/frpc" ]; then
  echo "Installing frpc..."
  curl -Lo /tmp/frp.tar.gz \
    "https://github.com/fatedier/frp/releases/download/v0.70.0/frp_0.70.0_linux_amd64.tar.gz"
  tar -xzf /tmp/frp.tar.gz -C /tmp/
  cp /tmp/frp_0.70.0_linux_amd64/frpc "$BIN/"
  rm -rf /tmp/frp.tar.gz /tmp/frp_0.70.0_linux_amd64
  echo "frpc installed"
else
  echo "frpc already installed"
fi

# ── playit ───────────────────────────────────────────────────────────────────
if [ ! -f "$BIN/playit" ]; then
  echo "Installing playit..."
  curl -Lo "$BIN/playit" \
    "https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
  chmod +x "$BIN/playit"
  echo "playit installed"
else
  echo "playit already installed"
fi

# ── PaperMC ──────────────────────────────────────────────────────────────────
PAPER_VERSION="26.2"
PAPER_BUILD="10"
PAPER_JAR="$MINECRAFT_DIR/paper-${PAPER_VERSION}.jar"

if [ ! -f "$PAPER_JAR" ]; then
  echo "Downloading PaperMC $PAPER_VERSION build $PAPER_BUILD..."
  PAPER_URL=$(curl -s -H "User-Agent: vlab-bootstrap/1.0" \
    "https://fill.papermc.io/v3/projects/paper/versions/${PAPER_VERSION}/builds" \
    | python3 -c "import sys,json; builds=json.load(sys.stdin); b=builds[-1]; print(b['downloads']['server:default']['url'])")
  curl -Lo "$PAPER_JAR" -H "User-Agent: vlab-bootstrap/1.0" "$PAPER_URL"
  echo "PaperMC downloaded"
else
  echo "PaperMC already downloaded"
fi

# ── server.properties ────────────────────────────────────────────────────────
if [ ! -f "$MINECRAFT_DIR/eula.txt" ]; then
  echo "eula=true" > "$MINECRAFT_DIR/eula.txt"
fi

if [ ! -f "$MINECRAFT_DIR/server.properties" ]; then
  cat > "$MINECRAFT_DIR/server.properties" << 'EOF'
online-mode=false
view-distance=6
simulation-distance=4
EOF
fi

# ── frpc config ──────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/frp"
if [ ! -f "$HOME/.config/frp/frpc.toml" ]; then
  cat > "$HOME/.config/frp/frpc.toml" << 'EOF'
# Fill in serverAddr and auth.token — see docs/frp.md
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
  echo "frpc config template created at ~/.config/frp/frpc.toml — fill in serverAddr and auth.token"
fi

echo ""
echo "Bootstrap complete. Run 'just' to see available commands."
