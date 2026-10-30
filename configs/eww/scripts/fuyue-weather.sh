#!/bin/bash
j=~/.cache/weather-om.json
jq -e '.current.temperature_2m' "$j" >/dev/null 2>&1 || { echo "Weather unavailable"; echo ""; echo ""; exit 0; }
temp=$(jq '.current.temperature_2m' "$j" | awk '{printf "%d", $1+0.5}')
hum=$(jq -r '.current.relative_humidity_2m' "$j")
wind=$(jq -r '.current.wind_speed_10m' "$j")
code=$(jq -r '.current.weather_code' "$j")
case "$code" in
  0) desc="clear sky" ;;
  1|2|3) desc="partly cloudy" ;;
  45|48) desc="fog" ;;
  51|53|55) desc="drizzle" ;;
  61|63|65|80|81|82) desc="rain" ;;
  71|73|75) desc="snow" ;;
  95|96|99) desc="thunderstorm" ;;
  *) desc="cloudy" ;;
esac
echo "Actual weather is ${desc}, temperature is ${temp}°C"
echo "with max temperature ${temp}°C and min temperature ${temp}°C"
echo "humidity in air is ${hum}% and wind speed ${wind}m/s"
