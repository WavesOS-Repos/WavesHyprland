#!/bin/bash
city_id=2950159
api_key="PASTE_YOUR_KEY_HERE"
unit=metric
lang=en
mkdir -p ~/.cache
curl -sS \
  "https://api.openweathermap.org/data/2.5/weather?id=${city_id}&appid=${api_key}&units=${unit}&lang=${lang}" \
  -o ~/.cache/weather.json
