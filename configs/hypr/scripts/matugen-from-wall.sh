#!/bin/bash
set -e
IMG="$1"
[[ -z "$IMG" || ! -f "$IMG" ]] && exit 1

MODE_FILE="$HOME/.config/hypr/.cache/.theme_mode"
MODE=$(cat "$MODE_FILE" 2>/dev/null || echo dark)
[[ "$MODE" == "light" ]] || MODE=dark

matugen image "$IMG" \
  --mode "$MODE" \
  --type scheme-vibrant \
  --contrast 1.0 \
  --source-color-index 0

mkdir -p "$HOME/.config/hypr/.cache"
cp -f "$IMG" "$HOME/.config/hypr/.cache/current_wallpaper.png"

hyprctl reload
pkill -x waybar 2>/dev/null || true
sleep 0.3
waybar &
