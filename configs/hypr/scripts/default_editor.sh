#!/usr/bin/env bash
# default_editor.sh — choose default code editor (rice cache + optional xdg)

set -euo pipefail

CACHE="$HOME/.config/hypr/.cache/.editor"
mkdir -p "$(dirname "$CACHE")"

# name|command|xdg_desktop (optional)
CANDIDATES=(
  "VS Code|code|code.desktop"
  "VS Code (code-oss)|code-oss|code-oss.desktop"
  "Cursor|cursor|cursor.desktop"
  "Neovim (Kitty)|nvim-kitty|"
  "Neovim|nvim|"
  "Helix|helix|"
  "Emacs|emacs|emacs.desktop"
  "Gedit|gedit|org.gnome.gedit.desktop"
  "Kate|kate|org.kde.kate.desktop"
  "Micro|micro|"
  "Nano|nano|"
)

declare -a NAMES=() CMDS=() DESKS=()

for e in "${CANDIDATES[@]}"; do
  IFS='|' read -r name cmd desk <<<"$e"
  if [[ "$cmd" == "nvim-kitty" ]]; then
    command -v nvim &>/dev/null && command -v kitty &>/dev/null || continue
    NAMES+=("$name"); CMDS+=("nvim-kitty"); DESKS+=("")
  elif command -v "$cmd" &>/dev/null; then
    NAMES+=("$name"); CMDS+=("$cmd"); DESKS+=("$desk")
  fi
done

if [[ ${#NAMES[@]} -eq 0 ]]; then
  notify-send "Default Editor" "No editors found"
  exit 1
fi

if command -v rofi &>/dev/null; then
    choice=$(printf '%s\n' "${NAMES[@]}" | rofi -dmenu -i -p "Default editor" \
      -theme "$HOME/.config/rofi/themes/rofi-screenshots.rasi")
else
  echo "Editors:"; i=1
  for n in "${NAMES[@]}"; do echo "  [$i] $n"; i=$((i+1)); done
  read -r -p "Number: " n
  choice="${NAMES[$((n-1))]:-}"
fi
[[ -z "${choice:-}" ]] && exit 0

idx=-1
for i in "${!NAMES[@]}"; do
  [[ "${NAMES[$i]}" == "$choice" ]] && idx=$i && break
done
[[ $idx -lt 0 ]] && exit 1

CMD="${CMDS[$idx]}"
DESK="${DESKS[$idx]}"

{
  echo "$CMD"
  echo "default=$CMD"
} > "$CACHE"

# XDG default for text/plain when we have a .desktop
if [[ -n "$DESK" ]]; then
  xdg-mime default "$DESK" text/plain 2>/dev/null || true
  xdg-mime default "$DESK" text/x-*" 2>/dev/null || true
fi

notify-send "Default Editor" "$choice ($CMD)"
echo "Default editor: $choice → $CMD"
