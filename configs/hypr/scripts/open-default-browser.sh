#!/usr/bin/env bash
# Launch the default browser (XDG / rice cache / fallback)

CACHE="$HOME/.config/hypr/.cache/.browser"
cmd=""

# 1) rice cache from default_browser.sh
if [[ -f "$CACHE" ]]; then
  cmd=$(grep -E '^default=' "$CACHE" | tail -1 | cut -d= -f2- | tr -d '[:space:]')
fi

# 2) $BROWSER
if [[ -z "$cmd" && -n "${BROWSER:-}" ]]; then
  cmd="$BROWSER"
fi

# 3) XDG default .desktop → try to run the app id
if [[ -z "$cmd" ]]; then
  desk=$(xdg-settings get default-web-browser 2>/dev/null || true)
  case "$desk" in
    firefox.desktop|firefox-esr.desktop) cmd=firefox ;;
    brave-browser.desktop|brave.desktop) cmd=brave ;;
    chromium.desktop) cmd=chromium ;;
    google-chrome.desktop|google-chrome-stable.desktop) cmd=google-chrome-stable ;;
    librewolf.desktop) cmd=librewolf ;;
    zen.desktop|zen-browser.desktop) cmd=zen-browser ;;
    vivaldi-stable.desktop|vivaldi.desktop) cmd=vivaldi ;;
    *) cmd="" ;;
  esac
fi

# 4) hard fallback
[[ -z "$cmd" ]] && cmd=firefox

if command -v "$cmd" &>/dev/null; then
  exec "$cmd" "$@"
else
  notify-send "Browser" "Command not found: $cmd"
  exit 1
fi
