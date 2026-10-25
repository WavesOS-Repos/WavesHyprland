#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

HYPR="${CONFIG_DIR}/hypr"
CACHE="${HYPR}/.cache"
SCRIPTS="${HYPR}/scripts"

mkdir -p "$CACHE"
[[ -d "$SCRIPTS" ]] && chmod +x "$SCRIPTS"/*.sh 2>/dev/null || true
[[ -f "${CONFIG_DIR}/qylock/sddm.sh" ]] && chmod +x "${CONFIG_DIR}/qylock/sddm.sh" 2>/dev/null || true

# ALWAYS dark — do NOT call theme-switch.sh (it may toggle to light)
echo dark > "${CACHE}/.theme_mode"

printf '%s\n' '[General]' 'theme=Relax-Kvantum' > "${CONFIG_DIR}/Kvantum/kvantum.kvconfig"
command -v kvantummanager &>/dev/null && kvantummanager --set Relax-Kvantum >/dev/null 2>&1 || true

for gtkver in gtk-3.0 gtk-4.0; do
  mkdir -p "${CONFIG_DIR}/${gtkver}"
  cat > "${CONFIG_DIR}/${gtkver}/settings.ini" << 'EOFINI'
[Settings]
gtk-theme-name=Relax-GTK
gtk-icon-theme-name=Relax-Dark-Icons
gtk-font-name=JetBrainsMono Nerd Font Propo Ultra-Bold 11
gtk-cursor-theme-name=default
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOFINI
done

if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface gtk-theme "Relax-GTK" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface icon-theme "Relax-Dark-Icons" >/dev/null 2>&1 || true
fi

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

# Never leave waybar attached to installer terminal
pkill -x waybar 2>/dev/null || true

if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  hyprctl reload >/dev/null 2>&1 || true
fi
