#!/bin/sh

if [ "$DESKTOP_SESSION" = "hyprland-uwsm" ]; then 
   sleep 20s
   killall conky
   cd "$HOME/.conky/Altair"
   conky -c "$HOME/.conky/Altair/Altair.conf" &
   exit 0
fi
