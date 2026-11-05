#!/usr/bin/env bash
# Open-Meteo → ~/.cache/weather-om.json  (matches fuyue-weather.sh)
set -u
CACHE="${HOME}/.cache"
OUT="${CACHE}/weather-om.json"
mkdir -p "$CACHE"

# Override with: export WAVES_LAT=.. WAVES_LON=..
LAT="${WAVES_LAT:-21.17}"
LON="${WAVES_LON:-72.83}"

URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m&timezone=auto"

curl -fsSL --max-time 15 "$URL" -o "$OUT" || echo '{"error":"fetch failed"}' > "$OUT"
