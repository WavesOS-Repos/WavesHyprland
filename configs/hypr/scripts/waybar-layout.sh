#!/bin/bash
# waybar-layout.sh — Switch between Waybar layouts cleanly

set -euo pipefail

# Directories
waybar_layouts="$HOME/.config/waybar/configs"
waybar_config="$HOME/.config/waybar/config"
waybar_styles="$HOME/.config/waybar/style"
waybar_style="$HOME/.config/waybar/style.css"
rofi_config="$HOME/.config/rofi/themes/rofi-waybar.rasi"

# Check required directories
if [[ ! -d "$waybar_layouts" || ! -d "$waybar_styles" ]]; then
    notify-send "Waybar" "Layout or style directory missing!" -u critical
    exit 1
fi

# Menu
menu() {
    find "$waybar_layouts" -maxdepth 1 -type f -printf "%f\n" | sort
}

# Apply selected layout
apply_config() {
    local choice="$1"
    local layout_file="$waybar_layouts/$choice"
    local style_file="$waybar_styles/$choice.css"

    if [[ ! -f "$layout_file" ]]; then
        notify-send "Waybar" "Layout not found: $choice" -u critical
        return 1
    fi

    if [[ ! -f "$style_file" ]]; then
        notify-send "Waybar" "Style not found: $choice.css" -u critical
        return 1
    fi

    # Create symlinks
    ln -sf "$layout_file" "$waybar_config"
    ln -sf "$style_file"  "$waybar_style"

    echo "Applied layout: $choice"

    # Restart Waybar safely
    restart_waybar
}

restart_waybar() {
    pkill -x waybar 2>/dev/null || true
    sleep 0.4
    waybar &
}

# Main
main() {
    # Close existing rofi if open
    if pgrep -x "rofi" > /dev/null; then
        pkill -x rofi
        exit 0
    fi

    choice=$(menu | rofi -dmenu -i -p "Waybar Layout" -config "$rofi_config" 2>/dev/null)

    if [[ -z "$choice" ]]; then
        echo "No selection made."
        exit 0
    fi

    apply_config "$choice"
}

main
