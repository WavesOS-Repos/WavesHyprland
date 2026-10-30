#!/bin/bash
j=~/.cache/weather-om.json
jq -e '.current.wind_speed_10m' "$j" >/dev/null 2>&1 || exit 0
speed=$(jq '.current.wind_speed_10m' "$j")
deg=$(jq '.current.wind_direction_10m' "$j")
dir="North"
(( $(echo "$deg > 22" | bc -l) )) && (( $(echo "$deg <= 67" | bc -l) )) && dir="North East"
# ... same sectors as before, or simplify:
python3 - <<'PY' 2>/dev/null || true
import json, pathlib
j=json.loads(pathlib.Path.home().joinpath(".cache/weather-om.json").read_text())
deg=j["current"]["wind_direction_10m"]
speed=j["current"]["wind_speed_10m"]
dirs=["North","North East","East","South East","South","South West","West","North West"]
print(f"Wind speed in your location is {speed}m/s blowing to the {dirs[int((deg+22.5)//45)%8]}")
PY
