#!/usr/bin/env bash
# EWW startup + wallpaper-change watchdog
# Restores main widget + optional visualizer (never forces a visualizer)
set -u

WIDGET_SH="${HOME}/.config/hypr/scripts/eww-widget.sh"
STATE_MAIN="${HOME}/.config/eww/active-widget"
STATE_VIS="${HOME}/.config/eww/active-visualizer"

sleep 2

if [[ ! -f "$STATE_MAIN" ]]; then
    mkdir -p "$(dirname "$STATE_MAIN")"
    echo "antares" > "$STATE_MAIN"
fi
if [[ ! -f "$STATE_VIS" ]]; then
    mkdir -p "$(dirname "$STATE_VIS")"
    echo "none" > "$STATE_VIS"
fi

bash "$WIDGET_SH" --ensure

get_wallpaper_state() {
    {
        pgrep -af 'mpvpaper|swww-daemon|swww img|awww-daemon|awww img|wallfliper' || true
    } | sort
}

last_state="$(get_wallpaper_state)"

while true; do
    sleep 2
    current_state="$(get_wallpaper_state)"

    if [[ "$current_state" != "$last_state" ]]; then
        last_state="$current_state"
        sleep 3
        bash "$WIDGET_SH" --ensure
        last_state="$(get_wallpaper_state)"
    fi

    # Recover main if it died
    main="$(cat "$STATE_MAIN" 2>/dev/null || echo none)"
    if [[ "$main" != "none" && -n "$main" ]]; then
        if ! eww active-windows 2>/dev/null | grep -qE "(^|,)${main}(,|$)|^${main}"; then
            # fallback match: window name present
            if ! eww active-windows 2>/dev/null | grep -q "${main}"; then
                bash "$WIDGET_SH" --ensure
            fi
        fi
    fi

    # Recover visualizer only if user enabled one
    vis="$(cat "$STATE_VIS" 2>/dev/null || echo none)"
    if [[ "$vis" != "none" && -n "$vis" ]]; then
        if ! eww active-windows 2>/dev/null | grep -q "${vis}"; then
            bash "$WIDGET_SH" --ensure
        fi
    fi
done
