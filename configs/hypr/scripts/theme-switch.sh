#!/usr/bin/env bash
# theme-switch.sh — dark/light for GTK + Kvantum; Matugen owns Kitty/Waybar/Rofi/Hyprland
set -euo pipefail

MODE_FILE="$HOME/.config/hypr/.cache/.theme_mode"
WALL="$HOME/.config/hypr/.cache/current_wallpaper.png"
MATUGEN="$HOME/.config/hypr/scripts/matugen-from-wall.sh"

# Kvantum (Qt: Dolphin, etc.) — exact folder names under ~/.config/Kvantum/
KV_DARK="Relax-Kvantum"
KV_LIGHT="Relax-Light-Kvantum"
KV_CONF="$HOME/.config/Kvantum/kvantum.kvconfig"

# GTK (Thunar, etc.) — only these; does NOT write Kitty config
GTK_DARK="Relax-GTK"
GTK_LIGHT="Relax-Light-GTK"

mkdir -p "$(dirname "$MODE_FILE")" "$HOME/.config/Kvantum"

CURRENT=$(cat "$MODE_FILE" 2>/dev/null || echo dark)
case "${1:-toggle}" in
  dark|light) NEW="$1" ;;
  *) [[ "$CURRENT" == "light" ]] && NEW=dark || NEW=light ;;
esac
echo "$NEW" > "$MODE_FILE"

# ── 1) Kvantum (Qt only) ──────────────────────────────────
if [[ "$NEW" == "light" ]]; then
  KV_THEME="$KV_LIGHT"
  GTK_THEME="$GTK_LIGHT"
  COLOR_SCHEME="prefer-light"
else
  KV_THEME="$KV_DARK"
  GTK_THEME="$GTK_DARK"
  COLOR_SCHEME="prefer-dark"
fi

if [[ -d "$HOME/.config/Kvantum/$KV_THEME" ]]; then
  printf '%s\n' '[General]' "theme=${KV_THEME}" > "$KV_CONF"
  command -v kvantummanager >/dev/null && kvantummanager --set "$KV_THEME" 2>/dev/null || true
else
  echo "WARN: Kvantum theme missing: $KV_THEME" >&2
fi

# Qt apps load style at start
pkill -x dolphin 2>/dev/null || true

# ── 2) GTK (Thunar / GTK apps only) ───────────────────────
# Prefer gsettings when available; also write settings.ini as fallback
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
fi

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
  if [[ -f "$ini" ]]; then
    grep -q '^\[Settings\]' "$ini" || printf '[Settings]\n' >> "$ini"
    if grep -q '^gtk-theme-name=' "$ini"; then
      sed -i "s|^gtk-theme-name=.*|gtk-theme-name=$GTK_THEME|" "$ini"
    else
      sed -i "/^\[Settings\]/a gtk-theme-name=$GTK_THEME" "$ini"
    fi
  else
    printf '[Settings]\ngtk-theme-name=%s\n' "$GTK_THEME" > "$ini"
  fi
done

# ── 3) Matugen LAST — restores Kitty / Waybar / Rofi / Hyprland ──
if [[ ! -f "$WALL" ]]; then
  WALL=$(find "$HOME/Pictures" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | head -1 || true)
fi

if [[ -n "${WALL:-}" && -f "$WALL" && -x "$MATUGEN" ]]; then
  # matugen-from-wall.sh must read .theme_mode and pass --mode
  "$MATUGEN" "$WALL"
else
  notify-send "Theme" "Mode=$NEW (GTK/Kvantum set). No wallpaper for Matugen."
  exit 0
fi

notify-send "Theme" "$NEW · GTK=$GTK_THEME · Kvantum=$KV_THEME · Matugen applied"
echo "Mode=$NEW  GTK=$GTK_THEME  Kvantum=$KV_THEME"
