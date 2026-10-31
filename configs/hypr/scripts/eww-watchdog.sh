#!/usr/bin/env bash
# EWW startup + wallpaper-change watchdog
# Restores the widget chosen by eww-widget.sh (not always antares)
set -u

WIDGET_SH="${HOME}/.config/hypr/scripts/eww-widget.sh"
STATE_FILE="${HOME}/.config/eww/active-widget"

sleep 2

# Default once if never set
if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "antares" > "$STATE_FILE"
fi

# Startup: daemon + saved widget
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
        # Re-open saved widget only if it disappeared
        bash "$WIDGET_SH" --ensure
        last_state="$(get_wallpaper_state)"
    fi

    # Also recover if user/session killed the open widget
    active="$(cat "$STATE_FILE" 2>/dev/null || echo none)"
    if [[ "$active" != "none" && -n "$active" ]]; then
        if ! eww active-windows 2>/dev/null | grep -q "^${active}"; then
            bash "$WIDGET_SH" --ensure
        fi
    fi
done
