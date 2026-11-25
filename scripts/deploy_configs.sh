#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/configs"
[[ -d "$SRC" ]] || die "Missing configs/"

# Prefer rsync; fall back to cp if rsync is broken (e.g. missing libcrypto)
copy_tree() {
  local from="$1" to="$2"
  mkdir -p "$to"
  if command -v rsync &>/dev/null && rsync --version &>/dev/null; then
    rsync -a \
      --exclude 'PLACEHOLDER.txt' \
      --exclude '.gitkeep' \
      --exclude '.gitkeep.txt' \
      "$from" "$to"
  else
    warn "rsync unavailable/broken — using cp"
    (
      cd "$from" || exit 1
      find . -type f \
        ! -name 'PLACEHOLDER.txt' \
        ! -name '.gitkeep' \
        ! -name '.gitkeep.txt' \
        -print0
    ) | while IFS= read -r -d '' rel; do
      rel="${rel#./}"
      mkdir -p "$to/$(dirname "$rel")"
      cp -a "$from/$rel" "$to/$rel"
    done
  fi
}

log "Deploying configs → $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
shopt -s nullglob

for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  if [[ -z "$(find "$dir" -type f ! -name 'PLACEHOLDER.txt' ! -name '.gitkeep' ! -name '.gitkeep.txt' 2>/dev/null | head -1)" ]]; then
    warn "skip empty configs/$name"
    continue
  fi
  copy_tree "$dir" "${CONFIG_DIR}/${name}/"
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
