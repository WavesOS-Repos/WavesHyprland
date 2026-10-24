#!/usr/bin/env bash
# rofi_theme.sh — horizontal preview grid (works on VM + bare metal)

rofiConf="${HOME}/.config/rofi/themes/rofi-select_theme.rasi"
rofiStyleDir="${HOME}/.config/rofi/menu"
rofiAssetDir="${HOME}/.config/rofi/assets"
menu_select_script="${HOME}/.config/hypr/scripts/menu.sh"

# Defaults when hypr vars missing (VM-safe)
rofiScale="${rofiScale:-10}"
hypr_border="${hypr_border:-2}"
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10

elem_border=$(( hypr_border * 5 ))
icon_border=$(( elem_border > 5 ? elem_border - 5 : 0 ))

# Prefer fixed columns so layout is always left/right on VMs
col_count=4
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  mon_x_res=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused==true) | .width' | head -1)
  mon_scale=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused==true) | .scale' | head -1)
  if [[ -n "$mon_x_res" && "$mon_x_res" =~ ^[0-9]+$ && -n "$mon_scale" ]]; then
    # scale 1.0 / 1.25 → integer percent (100, 125)
    scale_pct=$(awk -v s="$mon_scale" 'BEGIN{printf "%d", s*100}')
    [[ "$scale_pct" -ge 50 ]] || scale_pct=100
    mon_x_res=$(( mon_x_res * 100 / scale_pct ))
    elm_width=$(( (20 + 12 + 16) * rofiScale ))
    max_avail=$(( mon_x_res - (4 * rofiScale) ))
    if [[ "$elm_width" -gt 0 && "$max_avail" -gt 0 ]]; then
      col_count=$(( max_avail / elm_width ))
    fi
  fi
fi
[[ "$col_count" -lt 2 ]] && col_count=2
[[ "$col_count" -gt 5 ]] && col_count=5

# Force horizontal-style grid + visible icons (overrides weak VM calc)
r_override="window{width:100%;height:70%;}
listview{columns:${col_count};lines:2;layout:vertical;}
element{orientation:vertical;border-radius:${elem_border}px;}
element-icon{border-radius:${icon_border}px;size:12em;}
element-text{enabled:false;}"

mapfile -t style_files < <(ls "$rofiAssetDir"/style-*.png 2>/dev/null | sort -V)
if [[ ${#style_files[@]} -eq 0 ]]; then
  notify-send "Rofi theme" "No previews in $rofiAssetDir"
  exit 1
fi

rofi_list=""
for f in "${style_files[@]}"; do
  style_name="$(basename "$f")"
  rofi_list+="${style_name}\x00icon\x1f${f}\n"
done

selected_style="$(printf '%b' "$rofi_list" | rofi -dmenu -show-icons -markup-rows \
  -theme-str "$r_override" \
  -config "$rofiConf" \
  -p "Select Rofi theme" || true)"

echo "selected style: $selected_style"
[[ -n "${selected_style:-}" ]] || exit 0

selected_style_number="$(echo "$selected_style" | sed -n 's/^style-\([0-9]\+\)\.png.*/\1/p')"
[[ -n "$selected_style_number" ]] || exit 1

[[ -f "${rofiStyleDir}/style-${selected_style_number}.rasi" ]] || exit 1

if grep -qE '^theme=' "$menu_select_script"; then
  sed -i "s|^theme=.*|theme='style-${selected_style_number}'|" "$menu_select_script"
else
  sed -i "1a theme='style-${selected_style_number}'" "$menu_select_script"
fi

notify-send -t 2000 -i "${rofiAssetDir}/style-${selected_style_number}.png" "Theme applied" "style-${selected_style_number}"
