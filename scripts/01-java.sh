#!/usr/bin/env bash
# Install Zulu JDK 21 into $DATA_DIR/jdk (no root needed)
set -euo pipefail
source "$(dirname "$0")/_env.sh"

if [ -f "$DATA_DIR/jdk/bin/java" ]; then
  ok "Java already installed: $($DATA_DIR/jdk/bin/java -version 2>&1 | head -1)"
  exit 0
fi

info "Downloading JDK from $JAVA_URL"
curl -Lo /tmp/jdk.tar.gz "$JAVA_URL"
mkdir -p "$DATA_DIR/jdk"
tar -xzf /tmp/jdk.tar.gz -C "$DATA_DIR/jdk" --strip-components=1
rm /tmp/jdk.tar.gz
ok "Java installed: $($DATA_DIR/jdk/bin/java -version 2>&1 | head -1)"
