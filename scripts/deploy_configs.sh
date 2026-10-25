#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/configs"
[[ -d "$SRC" ]] || die "Missing configs/"

mkdir -p "$CONFIG_DIR"
shopt -s nullglob

for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  if [[ -z "$(find "$dir" -type f ! -name 'PLACEHOLDER.txt' ! -name '.gitkeep' ! -name '.gitkeep.txt' 2>/dev/null | head -1)" ]]; then
    continue
  fi
  mkdir -p "${CONFIG_DIR}/${name}"
  rsync -a --exclude 'PLACEHOLDER.txt' --exclude '.gitkeep' --exclude '.gitkeep.txt' "$dir" "${CONFIG_DIR}/${name}/"
done

for f in mimeapps.list kdeglobals; do
  [[ -f "$SRC/$f" ]] && cp -a "$SRC/$f" "${CONFIG_DIR}/$f"
done

# Rewrite packaging-machine paths everywhere
find "$CONFIG_DIR" -type l 2>/dev/null | while read -r link; do
  target="$(readlink "$link" || true)"
  [[ -n "$target" ]] || continue
  if [[ "$target" == /home/bowser/* ]]; then
    ln -sfn "${target/\/home\/bowser/${USER_HOME}}" "$link"
  fi
done

find "$CONFIG_DIR" -type f \( -name '*.rasi' -o -name '*.sh' -o -name '*.css' -o -name 'bookmarks' \
  -o -name '*.json' -o -name '*.jsonc' -o -name '*.lua' -o -name 'config' -o -name '*.conf' \) 2>/dev/null \
  | while read -r f; do
      sed -i "s|/home/bowser|${USER_HOME}|g" "$f" 2>/dev/null || true
      sed -i "s|/home/arch|${USER_HOME}|g" "$f" 2>/dev/null || true
    done

# Rofi colors link
mkdir -p "${CONFIG_DIR}/rofi/colors" "${CONFIG_DIR}/rofi/themes"
ROFI_COLORS="${CONFIG_DIR}/rofi/colors/colors-rofi.rasi"
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
fi
ln -sfn ../colors/colors-rofi.rasi "${CONFIG_DIR}/rofi/themes/rofi-colors.rasi"

rm -f "${CONFIG_DIR}/kitty/"*theme.auto.conf 2>/dev/null || true

# Waybar: fix broken module scripts under hypr/scripts if referenced with old paths
if [[ -d "${CONFIG_DIR}/waybar" ]]; then
  find "${CONFIG_DIR}/waybar" -type f \( -name '*.json*' -o -name '*.css' \) -exec \
    sed -i "s|/home/bowser|${USER_HOME}|g;s|/home/arch|${USER_HOME}|g" {} \; 2>/dev/null || true
fi
