#!/usr/bin/env bash
# Download and extract the modpack server pack into $MINECRAFT_DIR
# Requires SERVER_PACK_URL to be set in .env
set -euo pipefail
source "$(dirname "$0")/_env.sh"

if [ -z "${SERVER_PACK_URL:-}" ]; then
  ok "SERVER_PACK_URL not set — skipping (vanilla NeoForge)"
  exit 0
fi

if [ -d "$MINECRAFT_DIR/mods" ] && [ -n "$(ls -A "$MINECRAFT_DIR/mods" 2>/dev/null)" ]; then
  ok "Mods already installed ($(ls "$MINECRAFT_DIR/mods" | wc -l) mods)"
  exit 0
fi

info "Downloading server pack from CurseForge"
info "URL: $SERVER_PACK_URL"
curl -Lo /tmp/serverpack.zip "$SERVER_PACK_URL"

info "Extracting mods, config, and data files"
python3 - << 'PYEOF'
import zipfile, os, shutil, sys

src = "/tmp/serverpack.zip"
dst = os.environ["MINECRAFT_DIR"]

with zipfile.ZipFile(src) as z:
    members = z.namelist()
    # detect if the zip is wrapped in a single top-level folder (e.g. "overrides/")
    top_dirs = {m.split("/")[0] for m in members if "/" in m}
    prefix = (list(top_dirs)[0] + "/") if len(top_dirs) == 1 else ""

    keep = ("mods/", "config/", "defaultconfigs/", "kubejs/", "scripts/", "openloader/")
    # never overwrite these — the server manages them
    skip = {"server.properties", "eula.txt", "run.sh", "run.bat", "user_jvm_args.txt"}

    for member in members:
        rel = member[len(prefix):]
        if not rel:
            continue
        if not any(rel.startswith(k) for k in keep):
            continue
        if rel in skip or os.path.basename(rel) in skip:
            continue
        target = os.path.join(dst, rel)
        if member.endswith("/"):
            os.makedirs(target, exist_ok=True)
        else:
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with z.open(member) as src_f, open(target, "wb") as dst_f:
                shutil.copyfileobj(src_f, dst_f)

print("extraction complete")
PYEOF

rm /tmp/serverpack.zip
ok "Server pack extracted ($(ls "$MINECRAFT_DIR/mods" | wc -l) mods)"
