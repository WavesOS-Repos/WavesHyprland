#!/usr/bin/env bash

mpv --no-config --no-video --no-terminal \
    --really-quiet --volume=80 \
    "$HOME/.config/hypr/sounds/shutdown.mp3"

systemctl poweroff
