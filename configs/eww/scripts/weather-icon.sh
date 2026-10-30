#!/bin/bash
# Nerd Font / emoji fallback (Weathericons73 optional)
j=~/.cache/weather.json
[[ -f $j ]] || { echo "󰔏"; exit 0; }
icon=$(jq -r '.weather[0].icon' "$j")
case "$icon" in
  01d*) echo "󰖙" ;;
  01n*) echo "󰖔" ;;
  02d*) echo "󰖕" ;;
  02n*) echo "󰼱" ;;
  03*|04*) echo "󰖐" ;;
  09*|10*) echo "󰖗" ;;
  11*) echo "󰖓" ;;
  13*) echo "󰖘" ;;
  50*) echo "󰖑" ;;
  *) echo "󰔏" ;;
esac
