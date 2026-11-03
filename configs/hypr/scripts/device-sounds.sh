#!/bin/bash

SOUND_DIR="$HOME/.config/hypr/sounds"

case "$1" in
    add)
        SOUND="$SOUND_DIR/connected.mp3"
        ;;
    remove)
        SOUND="$SOUND_DIR/disconnected.mp3"
        ;;
    *)
        exit 1
        ;;
esac

[ -f "$SOUND" ] && mpv \
    --no-video \
    --really-quiet \
    --volume=70 \
    "$SOUND" &
