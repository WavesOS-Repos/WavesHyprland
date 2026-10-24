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

# Rewrite absolute paths from packaging machine
find "$CONFIG_DIR" -type l 2>/dev/null | while read -r link; do
  target="$(readlink "$link" || true)"
  [[ -n "$target" ]] || continue
  if [[ "$target" == /home/bowser/* ]]; then
    new="${target/\/home\/bowser/${USER_HOME}}"
    ln -sfn "$new" "$link"
    ok "retargeted symlink: $link"
  fi
done

find "$CONFIG_DIR" -type f \( -name '*.rasi' -o -name '*.sh' -o -name '*.css' -o -name 'bookmarks' -o -name '*.json' -o -name '*.jsonc' \) 2>/dev/null \
  | while read -r f; do
      sed -i "s|/home/bowser|${USER_HOME}|g" "$f" 2>/dev/null || true
    done

BOOKMARKS="${CONFIG_DIR}/gtk-3.0/bookmarks"
if [[ -f "$BOOKMARKS" ]]; then
  sed -i "s|/home/bowser|${USER_HOME}|g" "$BOOKMARKS" || true
fi

# Rofi Matugen colors: force correct link (never bowser)
mkdir -p "${CONFIG_DIR}/rofi/colors" "${CONFIG_DIR}/rofi/themes"
ROFI_COLORS="${CONFIG_DIR}/rofi/colors/colors-rofi.rasi"
# seed minimal palette if matugen has not run yet
if [[ ! -f "$ROFI_COLORS" ]]; then
  cat > "$ROFI_COLORS" << 'RASI'
* {
    background: #1e1e2e;
    foreground: #cdd6f4;
    selected:   #89b4fa;
    active:     #cba6f7;
    urgent:     #f38ba8;
}
RASI
  ok "seeded rofi colors-rofi.rasi"
fi
ln -sfn ../colors/colors-rofi.rasi "${CONFIG_DIR}/rofi/themes/rofi-colors.rasi"
ok "rofi-colors.rasi → colors/colors-rofi.rasi"

rm -f "${CONFIG_DIR}/kitty/"*theme.auto.conf 2>/dev/null || true
ok "Config deploy finished"
