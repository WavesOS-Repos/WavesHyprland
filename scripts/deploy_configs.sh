#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/configs"
[[ -d "$SRC" ]] || die "Missing configs/"

log "Deploying configs → $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
shopt -s nullglob

for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  if [[ -z "$(find "$dir" -type f ! -name 'PLACEHOLDER.txt' ! -name '.gitkeep' ! -name '.gitkeep.txt' 2>/dev/null | head -1)" ]]; then
    warn "skip empty configs/$name"
    continue
  fi
  mkdir -p "${CONFIG_DIR}/${name}"
  rsync -a --exclude 'PLACEHOLDER.txt' --exclude '.gitkeep' --exclude '.gitkeep.txt' "$dir" "${CONFIG_DIR}/${name}/"
  ok "deployed $name"
done

for f in mimeapps.list kdeglobals; do
  if [[ -f "$SRC/$f" ]]; then
    cp -a "$SRC/$f" "${CONFIG_DIR}/$f"
    ok "deployed $f"
  fi
done

BOOKMARKS="${CONFIG_DIR}/gtk-3.0/bookmarks"
if [[ -f "$BOOKMARKS" ]]; then
  sed -i "s|/home/bowser|${USER_HOME}|g" "$BOOKMARKS" || true
fi

rm -f "${CONFIG_DIR}/kitty/"*theme.auto.conf 2>/dev/null || true
ok "Config deploy finished"
