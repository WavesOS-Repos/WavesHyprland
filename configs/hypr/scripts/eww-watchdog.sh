
#!/usr/bin/env bash

# Eww startup + wallpaper-change watchdog
# Independent of Wallfliper and Matugen

set -u

sleep 2

# Start Eww if needed
if ! pgrep -x eww >/dev/null 2>&1; then
    eww daemon
    sleep 1
fi

# Open the widget once at startup
eww open antares >/dev/null 2>&1 || true

# Track wallpaper-related process changes
get_wallpaper_state() {
    {
        pgrep -af 'mpvpaper|swww-daemon|swww img|awww-daemon|awww img' || true
    } | sort
}

last_state="$(get_wallpaper_state)"

while true; do
    sleep 1
    current_state="$(get_wallpaper_state)"

    if [[ "$current_state" != "$last_state" ]]; then
        last_state="$current_state"

        # Wait until the wallpaper transition settles
        sleep 3

        # Refresh only if the Eww window is missing
        if ! eww windows 2>/dev/null | grep -q 'antares'; then
            eww open antares >/dev/null 2>&1 || true
        fi

        # Update the baseline after the transition
        last_state="$(get_wallpaper_state)"
    fi
done

