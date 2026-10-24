#!/usr/bin/env bash
# default_browser.sh — pick a browser and set it as system default (XDG) + rice cache

set -euo pipefail

CACHE="$HOME/.config/hypr/.cache/.browser"
mkdir -p "$(dirname "$CACHE")"

# name|desktop_file|command
CANDIDATES=(
  "Firefox|firefox.desktop|firefox"
  "Firefox ESR|firefox-esr.desktop|firefox-esr"
  "LibreWolf|librewolf.desktop|librewolf"
  "Zen Browser|zen.desktop|zen-browser"
  "Zen Browser|zen-browser.desktop|zen"
  "Brave|brave-browser.desktop|brave"
  "Brave|brave.desktop|brave"
  "Chromium|chromium.desktop|chromium"
  "Google Chrome|google-chrome.desktop|google-chrome-stable"
  "Google Chrome|google-chrome-stable.desktop|google-chrome-stable"
  "Vivaldi|vivaldi-stable.desktop|vivaldi"
  "Vivaldi|vivaldi.desktop|vivaldi"
  "Opera|opera.desktop|opera"
  "Microsoft Edge|microsoft-edge.desktop|microsoft-edge-stable"
)

declare -a MENU_NAMES=()
declare -a MENU_DESKTOPS=()
declare -a MENU_CMDS=()

add_if_present() {
  local name="$1" desktop="$2" cmd="$3"
  local i
  for i in "${MENU_CMDS[@]:-}"; do
    [[ "$i" == "$cmd" ]] && return
  done
  if command -v "$cmd" &>/dev/null || [[ -f "/usr/share/applications/$desktop" ]] \
    || [[ -f "$HOME/.local/share/applications/$desktop" ]]; then
    # prefer real binary if desktop exists without command in PATH
    if ! command -v "$cmd" &>/dev/null; then
      return
    fi
    MENU_NAMES+=("$name")
    MENU_DESKTOPS+=("$desktop")
    MENU_CMDS+=("$cmd")
  fi
}

for entry in "${CANDIDATES[@]}"; do
  IFS='|' read -r name desktop cmd <<<"$entry"
  add_if_present "$name" "$desktop" "$cmd"
done

if [[ ${#MENU_NAMES[@]} -eq 0 ]]; then
  notify-send "Default Browser" "No supported browsers found"
  echo "No browsers found."
  exit 1
fi

pick() {
  if command -v rofi &>/dev/null; then
    printf '%s\n' "${MENU_NAMES[@]}" | rofi -dmenu -i -p "Default browser" \
      -config "${HOME}/.config/rofi/themes/rofi-clipboard.rasi" 2>/dev/null \
      || printf '%s\n' "${MENU_NAMES[@]}" | rofi -dmenu -i -p "Default browser"
  elif command -v fzf &>/dev/null; then
    printf '%s\n' "${MENU_NAMES[@]}" | fzf --prompt="Default browser > "
  else
    echo "Installed browsers:"
    local i
    for i in "${!MENU_NAMES[@]}"; do
      echo "  [$((i + 1))] ${MENU_NAMES[$i]}"
    done
    local n
    read -r -p "Number: " n
    [[ "$n" =~ ^[0-9]+$ ]] || exit 1
    echo "${MENU_NAMES[$((n - 1))]}"
  fi
}

choice="$(pick)"
[[ -z "${choice:-}" ]] && exit 0

idx=-1
for i in "${!MENU_NAMES[@]}"; do
  if [[ "${MENU_NAMES[$i]}" == "$choice" ]]; then
    idx=$i
    break
  fi
done
[[ "$idx" -lt 0 ]] && exit 1

NAME="${MENU_NAMES[$idx]}"
DESKTOP="${MENU_DESKTOPS[$idx]}"
CMD="${MENU_CMDS[$idx]}"

# Resolve real .desktop if listed name missing
resolve_desktop() {
  local d="$1"
  for dir in /usr/share/applications "$HOME/.local/share/applications"; do
    [[ -f "$dir/$d" ]] && { echo "$d"; return; }
  done
  # fuzzy: first desktop matching command name
  local found
  found=$(find /usr/share/applications "$HOME/.local/share/applications" \
    -name '*firefox*' -o -name '*brave*' -o -name '*chrom*' -o -name '*vivaldi*' \
    -o -name '*opera*' -o -name '*librewolf*' -o -name '*zen*' 2>/dev/null | head -1)
  basename "${found:-$d}"
}

DESKTOP="$(resolve_desktop "$DESKTOP")"

# --- XDG system defaults ---
xdg-settings set default-web-browser "$DESKTOP" 2>/dev/null || true

for mime in \
  x-scheme-handler/http \
  x-scheme-handler/https \
  x-scheme-handler/about \
  x-scheme-handler/unknown \
  text/html \
  application/xhtml+xml
do
  xdg-mime default "$DESKTOP" "$mime" 2>/dev/null || true
done

# mimeapps.list hard set
MIMEAPPS="$HOME/.config/mimeapps.list"
mkdir -p "$HOME/.config"
if [[ -f "$MIMEAPPS" ]]; then
  # ensure Default Applications section has our entries
  grep -q '^\[Default Applications\]' "$MIMEAPPS" || echo -e "\n[Default Applications]" >> "$MIMEAPPS"
else
  printf '[Default Applications]\n' > "$MIMEAPPS"
fi

set_mime() {
  local key="$1"
  if grep -q "^${key}=" "$MIMEAPPS"; then
    sed -i "s|^${key}=.*|${key}=${DESKTOP}|" "$MIMEAPPS"
  else
    sed -i "/^\[Default Applications\]/a ${key}=${DESKTOP}" "$MIMEAPPS"
  fi
}

set_mime "text/html"
set_mime "x-scheme-handler/http"
set_mime "x-scheme-handler/https"
set_mime "x-scheme-handler/about"
set_mime "x-scheme-handler/unknown"
set_mime "application/xhtml+xml"

# --- rice cache for apps.sh ---
{
  echo "$CMD"
  echo "default=$CMD"
} > "$CACHE"

# optional env hint
export BROWSER="$CMD"

notify-send "Default Browser" "Set to $NAME ($DESKTOP)"
echo "Default browser: $NAME"
echo "  desktop: $DESKTOP"
echo "  command: $CMD"
echo "  check:   xdg-settings get default-web-browser"
echo "  test:    xdg-open https://example.com"
