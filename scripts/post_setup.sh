#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

HYPR="${CONFIG_DIR}/hypr"
CACHE="${HYPR}/.cache"
SCRIPTS="${HYPR}/scripts"

log "Post-setup"
mkdir -p "$CACHE"

if [[ -d "$SCRIPTS" ]]; then
  chmod +x "$SCRIPTS"/*.sh 2>/dev/null || true
  ok "chmod hypr/scripts"
fi

[[ -f "${CACHE}/.theme_mode" ]] || { echo dark > "${CACHE}/.theme_mode"; ok "theme_mode=dark"; }

MC="${HYPR}/matugen-colors.lua"
if [[ ! -f "$MC" ]]; then
  cat > "$MC" << 'LUA'
return {
    primary = "#89b4fa", secondary = "#cba6f7", tertiary = "#f5c2e7",
    background = "#1e1e2e", on_background = "#cdd6f4",
    surface = "#313244", outline = "#6c7086", error = "#f38ba8",
}
LUA
  ok "seeded matugen-colors.lua"
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
  ok "seeded colors-matugen.conf"
fi

rm -f "${KITTY}/"*theme.auto.conf 2>/dev/null || true

WALL_SRC="$ROOT/assets/default_wallpaper.png"
if [[ -f "$WALL_SRC" ]]; then
  cp -f "$WALL_SRC" "${CACHE}/current_wallpaper.png"
  ok "default wallpaper installed"
else
  warn "assets/default_wallpaper.png missing"
fi

command -v fc-cache &>/dev/null && fc-cache -f >/dev/null 2>&1 || true
ok "Post-setup complete"
