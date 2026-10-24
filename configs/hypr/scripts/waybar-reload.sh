#!/bin/bash
# waybar-reload.sh — Simple Waybar control

case "$1" in
    --reload)
        pkill -x waybar 2>/dev/null || true
        pkill -x swaync 2>/dev/null || true
        sleep 0.3
        waybar &
        swaync &
        ;;
    --toggle)
        if pgrep -x waybar > /dev/null; then
            pkill -x waybar
        else
            waybar &
        fi
        ;;
    *)
        echo "Usage: $0 --reload | --toggle"
        exit 1
        ;;
esac
