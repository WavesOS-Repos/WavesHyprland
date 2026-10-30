#!/bin/bash

OUT="$HOME/.config/eww/assets/fuyue-day.svg"
DAY=$(date +%-d)

mkdir -p "$HOME/.config/eww/assets"

COLOR=$(grep -E '^\s*\$primary:' "$HOME/.config/eww/colors.scss" 2>/dev/null \
  | head -1 | sed 's/.*:[[:space:]]*//;s/;.*//')

COLOR="${COLOR:-#b8d900}"
[[ "$COLOR" != \#* ]] && COLOR="#${COLOR}"

# Canvas is 340x620 to match the eww :image-width/:image-height below.
# The digit's baseline sits below the canvas on purpose so the bottom of
# the number is cropped — and the fade gradient hits 0 opacity exactly
# at that crop line, so the cut edge is invisible over the wallpaper.
cat > "$OUT" << EOF
<svg xmlns="http://www.w3.org/2000/svg"
     width="340" height="620"
     viewBox="0 0 340 620"
     preserveAspectRatio="xMidYMid slice">

  <defs>
    <linearGradient id="dateFade" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%"   stop-color="${COLOR}" stop-opacity="0.95"/>
      <stop offset="45%"  stop-color="${COLOR}" stop-opacity="0.45"/>
      <stop offset="75%"  stop-color="${COLOR}" stop-opacity="0.12"/>
      <stop offset="100%" stop-color="${COLOR}" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <text x="180" y="620"
        text-anchor="middle"
        font-family="Impact, Haettenschweiler, Arial Narrow Bold, sans-serif"
        font-size="350"
        font-weight="900"
        letter-spacing="-15"
        transform="translate(170 700) scale(0.72 1.55) translate(-170 -700)"
        fill="url(#dateFade)">${DAY}</text>
</svg>
EOF

echo "$OUT"
