#!/bin/bash

value_file="$HOME/.config/hypr/.cache/.nightlight"
default=6500

mkdir -p "$(dirname "$value_file")"
[[ ! -f "$value_file" ]] && echo "$default" > "$value_file"

value=$(cat "$value_file")

if command -v hyprsunset &>/dev/null; then
    case "$1" in
        --value)
            value=4000
            echo "$value" > "$value_file"
            notify-send "Nightlight" "Temperature set to 4000K"
            hyprsunset -t 4000
            ;;
        --def)
            value=$default
            echo "$value" > "$value_file"
            notify-send "Nightlight" "Reset to default"
            pkill -x hyprsunset
            ;;
        --inc)
            value=$((value + 100))
            ((value > 6500)) && value=6500
            echo "$value" > "$value_file"
            hyprsunset -t "$value"
            ;;
        --dec)
            value=$((value - 100))
            ((value < 3000)) && value=3000
            echo "$value" > "$value_file"
            hyprsunset -t "$value"
            ;;
    esac
fi

echo "${value}K"
