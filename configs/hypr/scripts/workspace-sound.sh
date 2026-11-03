#!/usr/bin/env bash

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
SOUND="$HOME/.config/hypr/sounds/workspace-switch.mp3"

socat -u "UNIX-CONNECT:$SOCKET" - | while IFS= read -r event; do
    case "$event" in
        workspace\>\>*|workspacev2\>\>*)
            mpv --no-config --no-video --no-terminal \
                --really-quiet --volume=25 "$SOUND" \
                >/dev/null 2>&1 &
            ;;
    esac
done
