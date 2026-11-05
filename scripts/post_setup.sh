#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

HYPR="${CONFIG_DIR}/hypr"
CACHE="${HYPR}/.cache"
SCRIPTS="${HYPR}/scripts"
EWW="${CONFIG_DIR}/eww"
CAVA="${CONFIG_DIR}/cava"
FONT_DIR="${USER_HOME}/.local/share/fonts/wavesos"
FONT_DIR_ALT="${USER_HOME}/.fonts"

mkdir -p "$CACHE" "$EWW/scripts" "$CAVA" "$FONT_DIR" "$FONT_DIR_ALT" "${USER_HOME}/.cache"

[[ -d "$SCRIPTS" ]] && chmod +x "$SCRIPTS"/*.sh 2>/dev/null || true
[[ -d "$EWW/scripts" ]] && chmod +x "$EWW/scripts"/* 2>/dev/null || true
[[ -f "${CONFIG_DIR}/qylock/sddm.sh" ]] && chmod +x "${CONFIG_DIR}/qylock/sddm.sh" 2>/dev/null || true

# Matugen seed
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

# Kitty colors seed
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

# Default wallpaper cache
WALL_SRC="$ROOT/assets/default_wallpaper.png"
[[ -f "$WALL_SRC" ]] && cp -f "$WALL_SRC" "${CACHE}/current_wallpaper.png" || true

# --- Fonts (Rock / EWW): Anurati, Chilanka, etc. from assets/fonts ---
if [[ -d "$ROOT/assets/fonts" ]]; then
  cp -a "$ROOT/assets/fonts/." "$FONT_DIR/" 2>/dev/null || true
  cp -a "$ROOT/assets/fonts/." "$FONT_DIR_ALT/" 2>/dev/null || true
fi
if [[ -n "${SUDO_USER:-}" ]]; then
  chown -R "${SUDO_USER}:${SUDO_USER}" "$FONT_DIR" "$FONT_DIR_ALT" 2>/dev/null || true
fi
if command -v fc-cache &>/dev/null; then
  fc-cache -f "${USER_HOME}/.local/share/fonts" >/dev/null 2>&1 || true
  fc-cache -f "${USER_HOME}/.fonts" >/dev/null 2>&1 || true
  fc-cache -f >/dev/null 2>&1 || true
fi
if command -v fc-list &>/dev/null; then
  fc-list 2>/dev/null | grep -qi Anurati || warn "Anurati not found — add assets/fonts/Anurati.otf"
  fc-list 2>/dev/null | grep -qi Chilanka || warn "Chilanka not found — add assets/fonts/Chilanka-Regular.ttf"
fi

# Cava config for EWW visualizers
if [[ ! -f "${CAVA}/eww-cava.conf" ]]; then
  cat > "${CAVA}/eww-cava.conf" << 'CAVA'
[general]
framerate = 12
bars = 48
autosens = 1
sensitivity = 100

[input]
method = pulse

[output]
method = ascii
ascii_max_range = 100
channels = mono
CAVA
fi

# Initial SVGs so EWW image widgets have a path
mkdir -p /tmp/eww-waveform /tmp/eww-waveform-vertical
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="300"></svg>' \
  > /tmp/eww-waveform/initial.svg
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="1080"></svg>' \
  > /tmp/eww-waveform-vertical/initial.svg

# EWW state defaults
[[ -f "${EWW}/active-widget" ]] || echo "fuyue" > "${EWW}/active-widget"
[[ -f "${EWW}/active-visualizer" ]] || echo "none" > "${EWW}/active-visualizer"

# Weather (Open-Meteo → weather-om.json) — no API key
if [[ -x "${EWW}/scripts/weather-fetch.sh" ]]; then
  bash "${EWW}/scripts/weather-fetch.sh" >/dev/null 2>&1 || true
elif [[ -f "${EWW}/scripts/weather-fetch.sh" ]]; then
  bash "${EWW}/scripts/weather-fetch.sh" >/dev/null 2>&1 || true
fi

pkill -x waybar 2>/dev/null || true

THEME_SWITCH="${SCRIPTS}/theme-switch.sh"
if [[ -f "$THEME_SWITCH" ]]; then
  echo dark > "${CACHE}/.theme_mode"
  bash "$THEME_SWITCH" >/dev/null 2>&1 || true
  bash "$THEME_SWITCH" >/dev/null 2>&1 || true
else
  warn "theme-switch.sh not found at $THEME_SWITCH"
  echo dark > "${CACHE}/.theme_mode"
fi

pkill -x waybar 2>/dev/null || true

if command -v hyprctl &>/dev/null; then
  hyprctl reload >/dev/null 2>&1 || true
fi

# Warm EWW daemon (does not force visualizer)
if command -v eww &>/dev/null; then
  eww daemon >/dev/null 2>&1 || true
  if [[ -x "${SCRIPTS}/eww-widget.sh" ]]; then
    bash "${SCRIPTS}/eww-widget.sh" --ensure >/dev/null 2>&1 || true
  fi
fi
