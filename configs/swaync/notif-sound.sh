#!/bin/bash

mpv \
    --no-config \
    --no-video \
    --no-terminal \
    --really-quiet \
    --volume=65 \
    "$HOME/.config/hypr/sounds/notif.mp3" \
    >/dev/null 2>&1 &
