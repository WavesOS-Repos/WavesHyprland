#!/usr/bin/env bash

if hyprctl clients -j | jq -e '[.[] | select(.floating == false)] | length > 0' >/dev/null; then
    hyprctl --batch "dispatch workspaceopt allfloat"
else
    hyprctl --batch "dispatch workspaceopt allfloat"
fi
