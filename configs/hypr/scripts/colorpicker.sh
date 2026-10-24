#!/usr/bin/env bash
# colorpicker.sh — pick a pixel color and copy to clipboard

set -euo pipefail

if ! command -v hyprpicker &>/dev/null; then
  notify-send "Color picker" "Install hyprpicker first"
  exit 1
fi

# -a = auto copy when supported; we also force wl-copy
color=$(hyprpicker -a -n 2>/dev/null || hyprpicker -n)

[[ -z "${color:-}" ]] && exit 0

# normalize (hyprpicker usually returns #RRGGBB)
color=$(echo "$color" | tr -d '[:space:]')
echo -n "$color" | wl-copy

notify-send -t 2000 "Color picked" "$color"
