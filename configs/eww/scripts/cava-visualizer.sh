#!/usr/bin/env bash
# Streams JSON arrays of bar heights for EWW: [0,12,40,...]

FIFO="/tmp/cava-eww.fifo"
CAVA_CFG="${HOME}/.config/cava/eww-visualizer"
BARS=48
MAX_PX=120

rm -f "$FIFO"
mkfifo "$FIFO"

# Cava writes raw 8-bit samples to the fifo
cava -p "$CAVA_CFG" > /dev/null 2>&1 &
CAVA_PID=$!

cleanup() {
  kill "$CAVA_PID" 2>/dev/null
  rm -f "$FIFO"
}
trap cleanup EXIT INT TERM

# Read raw bytes → JSON array of pixel heights
while true; do
  if read -r -N "$BARS" data < "$FIFO"; then
    out="["
    first=1
    for ((i = 0; i < BARS; i++)); do
      # byte value 0–255
      byte=$(printf '%d' "'${data:i:1}")
      h=$(( byte * MAX_PX / 255 ))
      if (( first )); then
        out+="${h}"
        first=0
      else
        out+=",${h}"
      fi
    done
    out+="]"
    echo "$out"
  else
    sleep 0.05
  fi
done
