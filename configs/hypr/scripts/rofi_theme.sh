#!/usr/bin/env bash
# Rofi style switcher — styles in menu/, previews in assets/
set -euo pipefail

ROFI_DIR="${HOME}/.config/rofi"
ASSETS="${ROFI_DIR}/assets"
MENU="${ROFI_DIR}/menu"
CURRENT="${ROFI_DIR}/menu.rasi"   # or whatever you launch with; adjust if needed

# Prefer active theme file used by menu.sh — common patterns:
#   ~/.config/rofi/config.rasi include, or menu.sh -theme menu/style-N.rasi
# This script sets a symlink menu/current.rasi and optional marker.

mkdir -p "$ASSETS" "$MENU"

mapfile -t STYLES < <(find "$MENU" -maxdepth 1 -type f -name 'style-*.rasi' | sort -V)
if [[ ${#STYLES[@]} -eq 0 ]]; then
  notify-send "Rofi theme" "No style-*.rasi in $MENU" 2>/dev/null || echo "No styles in $MENU"
  exit 1
fi

# Build list: style-1, style-2, ...
LIST=""
for f in "${STYLES[@]}"; do
  base="$(basename "$f" .rasi)"          # style-1
  icon="${ASSETS}/${base}.png"
  if [[ -f "$icon" ]]; then
    LIST+="${base}\0icon\x1f${icon}\n"
  else
    LIST+="${base}\n"
  fi
done

CHOSEN="$(printf '%b' "$LIST" | rofi -dmenu -i -p "Rofi style" -show-icons -theme "${MENU}/style-1.rasi" || true)"
[[ -n "${CHOSEN:-}" ]] || exit 0

# strip possible markup / trailing junk
CHOSEN="$(echo "$CHOSEN" | awk '{print $1}')"
TARGET="${MENU}/${CHOSEN}.rasi"
[[ -f "$TARGET" ]] || { echo "Missing $TARGET"; exit 1; }

# Point launcher at selected style
ln -sfn "menu/${CHOSEN}.rasi" "${ROFI_DIR}/current-style.rasi" 2>/dev/null || \
  ln -sfn "${TARGET}" "${ROFI_DIR}/current-style.rasi"

# If menu.sh uses a fixed path, update that convention:
# e.g. symlink menu.rasi → style-N
ln -sfn "${CHOSEN}.rasi" "${MENU}/../selected.rasi" 2>/dev/null || true
ln -sfn "${TARGET}" "${ROFI_DIR}/selected.rasi"

# Persist name for menu.sh
echo "$CHOSEN" > "${ROFI_DIR}/.current-style"

notify-send "Rofi theme" "Selected ${CHOSEN}" 2>/dev/null || echo "Selected ${CHOSEN}"
