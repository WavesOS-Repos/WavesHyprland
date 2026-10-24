#!/usr/bin/env bash
# open-default-editor.sh — launch default editor (optional path args)

CACHE="$HOME/.config/hypr/.cache/.editor"
cmd=""

if [[ -f "$CACHE" ]]; then
  cmd=$(grep -E '^default=' "$CACHE" | tail -1 | cut -d= -f2- | tr -d '[:space:]')
fi
[[ -z "$cmd" ]] && cmd="code"

case "$cmd" in
  nvim-kitty)
    exec kitty --class editor -e nvim "$@"
    ;;
  nvim|helix|micro|nano)
    if command -v kitty &>/dev/null; then
      exec kitty --class editor -e "$cmd" "$@"
    else
      exec "$cmd" "$@"
    fi
    ;;
  *)
    if command -v "$cmd" &>/dev/null; then
      exec "$cmd" "$@"
    else
      notify-send "Editor" "Not found: $cmd — run default_editor.sh"
      exit 1
    fi
    ;;
esac
