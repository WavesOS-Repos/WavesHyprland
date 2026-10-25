#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

HYPR="${CONFIG_DIR}/hypr"
CACHE="${HYPR}/.cache"
SCRIPTS="${HYPR}/scripts"

mkdir -p "$CACHE"
[[ -d "$SCRIPTS" ]] && chmod +x "$SCRIPTS"/*.sh 2>/dev/null || true
[[ -f "${CONFIG_DIR}/qylock/sddm.sh" ]] && chmod +x "${CONFIG_DIR}/qylock/sddm.sh" 2>/dev/null || true

MC="${HYPR}/matugen-colors.lua"
if [[ ! -f "$MC" ]]; then
  cat > "$MC" << 'LUA'
return {
    primary = "#89b4fa", secondary = "#cba6f7", tertiary = "#f5c2e7",
    background = "#1e1e2e", on_background = "#cdd6f4",
    surface = "#313244", outline = "#6c7086", error = "#f38ba8",
}
LUA
fi

KITTY="${CONFIG_DIR}/kitty"
mkdir -p "$KITTY"
if [[ ! -f "${KITTY}/colors-matugen.conf" ]]; then
  cat > "${KITTY}/colors-matugen.conf" << 'KIT'
foreground #cdd6f4
background #1e1e2e
cursor #cdd6f4
color0 #1e1e2e
color1 #f38ba8
color2 #a6e3a1
color3 #f9e2af
color4 #89b4fa
color5 #cba6f7
color6 #94e2d5
color7 #cdd6f4
color8 #6c7086
color9 #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #cba6f7
color14 #94e2d5
color15 #cdd6f4
KIT
fi
rm -f "${KITTY}/"*theme.auto.conf 2>/dev/null || true

WALL_SRC="$ROOT/assets/default_wallpaper.png"
[[ -f "$WALL_SRC" ]] && cp -f "$WALL_SRC" "${CACHE}/current_wallpaper.png" || true

command -v fc-cache &>/dev/null && fc-cache -f >/dev/null 2>&1 || true

pkill -x waybar 2>/dev/null || true

THEME_SWITCH="${SCRIPTS}/theme-switch.sh"
if [[ -f "$THEME_SWITCH" ]]; then
  if ! bash "$THEME_SWITCH" --dark >/dev/null 2>&1; then
    warn "theme-switch.sh --dark failed"
  fi
else
  warn "theme-switch.sh not found at $THEME_SWITCH"
  echo dark > "${CACHE}/.theme_mode"
fi

pkill -x waybar 2>/dev/null || true

if command -v hyprctl &>/dev/null; then
  hyprctl reload >/dev/null 2>&1 || true
fi
