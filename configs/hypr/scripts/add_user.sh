#!/usr/bin/env bash
# add_user.sh — set Hyprlock profile photo → ~/.config/hypr/.cache/user.png

set -euo pipefail

OUT="$HOME/.config/hypr/.cache/user.png"
mkdir -p "$(dirname "$OUT")"

if [[ -n "${1:-}" ]]; then
  img_path="$1"
else
  printf "Path to image for Hyprlock profile (e.g. ~/Pictures/me.jpg)\n"
  read -r -p "Paste here: " img_path
fi

# expand ~
img_path="${img_path/#\~/$HOME}"

if [[ ! -f "$img_path" ]]; then
  echo "[ ! ] File not found: $img_path"
  exit 1
fi

if command -v magick &>/dev/null; then
  magick "$img_path" -resize 400x400^ -gravity center -extent 400x400 "$OUT"
elif command -v convert &>/dev/null; then
  convert "$img_path" -resize 400x400^ -gravity center -extent 400x400 "$OUT"
else
  echo "[ ! ] ImageMagick required (magick or convert)"
  exit 1
fi

echo "[ * ] Saved: $OUT"
echo "      Hyprlock uses this as the profile image."
