#!/bin/bash
j=~/.cache/weather-om.json
h=$(jq -r '.current.relative_humidity_2m' "$j")
echo "And humidity is ${h}%."
