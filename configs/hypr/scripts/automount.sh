#!/bin/bash

# Automatic storage mounting for Hyprland

MOUNT_DIR="/run/media/$USER"

mkdir -p "$MOUNT_DIR"

# Wait for UDisks2 to initialize
sleep 2

# Start udiskie in the background
udiskie \
    --automount \
    --notify \
    --tray \
    --file-manager thunar
