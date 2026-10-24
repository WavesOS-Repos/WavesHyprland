#!/usr/bin/env bash
# zoom.sh — Hyprland cursor zoom (no extra plugin)
# Usage: zoom.sh | zoom.sh --in | zoom.sh --out | zoom.sh --reset

set -euo pipefail

CACHE="$HOME/.config/hypr/.cache/.zoom_factor"
mkdir -p "$(dirname "$CACHE")"
[[ -f "$CACHE" ]] || echo "1.0" > "$CACHE"

cur=$(cat "$CACHE")
# clamp helper via awk
clamp() { awk -v v="$1" 'BEGIN{ if(v<1)v=1; if(v>3)v=3; printf "%.1f", v }'; }

case "${1:-}" in
  --in)
    new=$(clamp "$(echo "$cur + 0.2" | bc -l)")
    ;;
  --out)
    new=$(clamp "$(echo "$cur - 0.2" | bc -l)")
    ;;
  --reset)
    new="1.0"
    ;;
  *)
    # toggle 1.0 <-> 2.0
    if awk -v c="$cur" 'BEGIN{exit !(c+0 > 1.05)}'; then
      new="1.0"
    else
      new="2.0"
    fi
    ;;
esac

echo "$new" > "$CACHE"
hyprctl keyword cursor:zoom_factor "$new"
notify-send -t 800 "Zoom" "${new}x"
