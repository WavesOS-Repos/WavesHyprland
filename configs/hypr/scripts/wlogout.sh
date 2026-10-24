#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/wlogout"
MODE_FILE="$HOME/.config/hypr/.cache/.theme_mode"

MODE=$(cat "$MODE_FILE" 2>/dev/null || printf 'dark')

case "$MODE" in
    light) CSS="$CONFIG/style-light.css" ;;
    *)     CSS="$CONFIG/style-dark.css" ;;
esac

cd "$CONFIG"
exec wlogout \
    --layout "$CONFIG/layout" \
    --css "$CSS" \
    --protocol layer-shell

