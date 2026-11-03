
#!/usr/bin/env bash

SOUND_DIR="$HOME/.config/hypr/sounds"

# Prevent multiple listener instances
LOCK="$XDG_RUNTIME_DIR/hypr-device-sounds.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

play_sound() {
    local action="$1"
    local sound

    case "$action" in
        add)    sound="$SOUND_DIR/connected.mp3" ;;
        remove) sound="$SOUND_DIR/disconnected.mp3" ;;
        *)      return ;;
    esac

    if [[ -f "$sound" ]]; then
        mpv --no-config \
            --no-video \
            --no-terminal \
            --really-quiet \
            --volume=70 \
            "$sound" >/dev/null 2>&1 &
    fi
}

action=""
devtype=""

handle_event() {
    if [[ "$devtype" == "usb_device" ]]; then
        case "$action" in
            add|remove)
                play_sound "$action"
                ;;
        esac
    fi
}

# Listen for USB hardware events without polling
udevadm monitor --udev --property --subsystem-match=usb |
while IFS= read -r line; do

    if [[ "$line" =~ ^UDEV[[:space:]] ]]; then
        handle_event

        action="${line#*] }"
        action="${action%% *}"
        devtype=""

    elif [[ "$line" == DEVTYPE=* ]]; then
        devtype="${line#DEVTYPE=}"

    elif [[ -z "$line" ]]; then
        handle_event
        action=""
        devtype=""
    fi

done

