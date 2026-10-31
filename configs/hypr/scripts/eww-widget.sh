#!/usr/bin/env bash
# EWW widget switcher (Rofi) + state for watchdog
set -u

ROFI_THEME="${HOME}/.config/rofi/themes/rofi-desktop-widget.rasi"
STATE_FILE="${HOME}/.config/eww/active-widget"
WIDGETS=("antares" "fuyue" "rock")

ensure_daemon() {
    if ! pgrep -x eww >/dev/null 2>&1; then
        eww daemon
        sleep 1
    fi
}

close_all() {
    for w in "${WIDGETS[@]}"; do
        eww close "$w" 2>/dev/null || true
    done
}

# $1 = widget name | "none"
set_active() {
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$1" > "$STATE_FILE"
}

get_active() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "antares"
    fi
}

open_active() {
    local w
    w="$(get_active)"
    [[ "$w" == "none" || -z "$w" ]] && return 0
    ensure_daemon
    # close others so only the saved one is up
    for x in antares fuyue rock; do
        [[ "$x" == "$w" ]] && continue
        eww close "$x" 2>/dev/null || true
    done
    eww open "$w" >/dev/null 2>&1 || true
}

# --- CLI modes for watchdog / autostart ---
case "${1:-}" in
    --ensure)
        # start daemon + open saved widget (no rofi)
        ensure_daemon
        open_active
        exit 0
        ;;
    --restore)
        # close all then open saved widget
        ensure_daemon
        close_all
        open_active
        exit 0
        ;;
esac

# --- Rofi switcher ---
ensure_daemon

menu="󰖨  Antares\n󰃭  Fuyue\n󰥔  Rock\n󰅖  Close all"
choice=$(echo -e "$menu" | rofi -dmenu -i \
    -p "EWW Widget" \
    -theme "$ROFI_THEME" \
    -theme-str 'entry { placeholder: " Select widget"; }')

[[ -z "$choice" ]] && exit 0

case "$choice" in
    *Antares*)
        set_active "antares"
        close_all
        eww open antares
        notify-send -t 1500 "EWW" "Antares"
        ;;
    *Fuyue*)
        set_active "fuyue"
        close_all
        eww open fuyue
        notify-send -t 1500 "EWW" "Fuyue"
        ;;
    *Rock*)
        set_active "rock"
        close_all
        eww open rock
        notify-send -t 1500 "EWW" "Rock"
        ;;
    *Close*)
        set_active "none"
        close_all
        notify-send -t 1500 "EWW" "All widgets closed"
        ;;
esac
