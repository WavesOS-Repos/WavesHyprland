#!/usr/bin/env bash
# EWW widget switcher (Rofi) + state for watchdog
# Main widgets (antares/fuyue/rock) and visualizers are independent.
# Only the two visualizers turn each other off.
set -u

ROFI_THEME="${HOME}/.config/rofi/themes/rofi-desktop-widget.rasi"
STATE_MAIN="${HOME}/.config/eww/active-widget"
STATE_VIS="${HOME}/.config/eww/active-visualizer"

MAIN_WIDGETS=("antares" "fuyue" "rock")
VIS_WIDGETS=("audio-wave" "visualizer-vertical")
ALL_WIDGETS=("antares" "fuyue" "rock" "audio-wave" "visualizer-vertical")

ensure_daemon() {
    if ! pgrep -x eww >/dev/null 2>&1; then
        eww daemon
        sleep 1
    fi
}

close_mains() {
    local w
    for w in "${MAIN_WIDGETS[@]}"; do
        eww close "$w" 2>/dev/null || true
    done
}

close_visualizers() {
    local w
    for w in "${VIS_WIDGETS[@]}"; do
        eww close "$w" 2>/dev/null || true
    done
}

close_all() {
    local w
    for w in "${ALL_WIDGETS[@]}"; do
        eww close "$w" 2>/dev/null || true
    done
}

set_main() {
    mkdir -p "$(dirname "$STATE_MAIN")"
    echo "$1" > "$STATE_MAIN"
}

set_vis() {
    mkdir -p "$(dirname "$STATE_VIS")"
    echo "$1" > "$STATE_VIS"
}

get_main() {
    if [[ -f "$STATE_MAIN" ]]; then
        cat "$STATE_MAIN"
    else
        echo "antares"
    fi
}

get_vis() {
    if [[ -f "$STATE_VIS" ]]; then
        cat "$STATE_VIS"
    else
        echo "none"
    fi
}

open_main() {
    local w
    w="$(get_main)"
    [[ "$w" == "none" || -z "$w" ]] && return 0
    ensure_daemon
    close_mains
    eww open "$w" >/dev/null 2>&1 || true
}

open_vis() {
    local w
    w="$(get_vis)"
    [[ "$w" == "none" || -z "$w" ]] && return 0
    ensure_daemon
    # only one visualizer
    close_visualizers
    eww open "$w" >/dev/null 2>&1 || true
}

# --- CLI modes for watchdog / autostart ---
case "${1:-}" in
    --ensure)
        ensure_daemon
        open_main
        open_vis
        exit 0
        ;;
    --restore)
        ensure_daemon
        close_all
        open_main
        open_vis
        exit 0
        ;;
esac

# --- Rofi switcher ---
ensure_daemon

menu="󰖨  Antares\n󰃭  Fuyue\n󰥔  Rock\n_  Audio-Horz\n|  Audio-Vert\n󰅖  Close visualizer\n󰅖  Close all"
choice=$(echo -e "$menu" | rofi -dmenu -i \
    -p "EWW Widget" \
    -theme "$ROFI_THEME" \
    -theme-str 'entry { placeholder: " Select widget"; }')

[[ -z "$choice" ]] && exit 0

case "$choice" in
    *Antares*)
        set_main "antares"
        close_mains
        eww open antares
        notify-send -t 1500 "EWW" "Antares"
        ;;
    *Fuyue*)
        set_main "fuyue"
        close_mains
        eww open fuyue
        notify-send -t 1500 "EWW" "Fuyue"
        ;;
    *Rock*)
        set_main "rock"
        close_mains
        eww open rock
        notify-send -t 1500 "EWW" "Rock"
        ;;
    *Audio-Horz*)
        set_vis "audio-wave"
        eww close visualizer-vertical 2>/dev/null || true
        eww open audio-wave
        notify-send -t 1500 "EWW" "Audio horizontal"
        ;;
    *Audio-Vert*)
        set_vis "visualizer-vertical"
        eww close audio-wave 2>/dev/null || true
        eww open visualizer-vertical
        notify-send -t 1500 "EWW" "Audio vertical"
        ;;
    *Close\ visualizer*)
        set_vis "none"
        close_visualizers
        notify-send -t 1500 "EWW" "Visualizer closed"
        ;;
    *Close\ all*)
        set_main "none"
        set_vis "none"
        close_all
        notify-send -t 1500 "EWW" "All widgets closed"
        ;;
esac
