#!/usr/bin/env bash
# Usage: matugen-from-wall.sh /path/to/image_or_video
set -u

IMG="${1:-}"
if [[ -z "$IMG" || ! -e "$IMG" ]]; then
  echo "matugen-from-wall: missing or invalid path: ${IMG:-<empty>}" >&2
  exit 1
fi

# If video, extract one frame for matugen
WORK="$IMG"
case "${IMG,,}" in
  *.mp4|*.webm|*.mkv|*.avi|*.mov)
    if command -v ffmpeg >/dev/null 2>&1; then
      WORK="${TMPDIR:-/tmp}/matugen-frame-$$.png"
      ffmpeg -y -i "$IMG" -frames:v 1 "$WORK" >/dev/null 2>&1 || {
        echo "matugen-from-wall: ffmpeg failed on video" >&2
        exit 1
      }
    else
      echo "matugen-from-wall: video needs ffmpeg" >&2
      exit 1
    fi
    ;;
esac

if [[ ! -f "$WORK" ]]; then
  echo "matugen-from-wall: not a file: $WORK" >&2
  exit 1
fi

MODE_FILE="${HOME}/.config/hypr/.cache/.theme_mode"
MODE="$(cat "$MODE_FILE" 2>/dev/null || echo dark)"
[[ "$MODE" == "light" ]] || MODE="dark"

mkdir -p "${HOME}/.config/hypr/.cache"

# Prefer full CLI; fall back if flags unsupported
if ! matugen image "$WORK" \
      --mode "$MODE" \
      --type scheme-vibrant \
      --contrast 1.0 \
      --source-color-index 1
then
  echo "matugen-from-wall: retrying simpler matugen invocation..." >&2
  matugen image "$WORK" --mode "$MODE" || {
    echo "matugen-from-wall: matugen failed" >&2
    [[ "$WORK" != "$IMG" ]] && rm -f "$WORK"
    exit 1
  }
fi

# Cache still for restore / other tools (prefer original image; for video use frame)
if [[ "$WORK" != "$IMG" ]]; then
  cp -f "$WORK" "${HOME}/.config/hypr/.cache/current_wallpaper.png"
  rm -f "$WORK"
else
  cp -f "$IMG" "${HOME}/.config/hypr/.cache/current_wallpaper.png"
fi

command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true

# Never fail the script if waybar isn't running
pkill -x waybar 2>/dev/null || true
sleep 0.3
if command -v waybar >/dev/null 2>&1; then
  waybar >/dev/null 2>&1 &
fi

# Refresh eww colors if present
command -v eww >/dev/null 2>&1 && eww reload >/dev/null 2>&1 || true

echo "matugen-from-wall: ok ($MODE) ← $IMG"
exit 0
