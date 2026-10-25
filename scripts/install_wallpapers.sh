#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

DEST="${USER_HOME}/Pictures/Wallpapers"
REPO="https://github.com/WavesOS-Repos/WavesWallpapers.git"

mkdir -p "${USER_HOME}/Pictures"

if [[ -d "$DEST/.git" ]]; then
  run_quiet "update Wallpapers repo" git -C "$DEST" pull --ff-only \
    || warn "git pull failed for $DEST (keeping existing files)"
elif [[ -d "$DEST" ]] && [[ -n "$(ls -A "$DEST" 2>/dev/null || true)" ]]; then
  warn "$DEST already exists and is not a git repo — skip clone"
else
  rm -rf "$DEST"
  run_quiet "clone WavesWallpapers" git clone --depth 1 "$REPO" "$DEST" \
    || die "Failed to clone $REPO → $DEST"
fi

# ownership if ran with sudo
if [[ -n "${SUDO_USER:-}" && "$(id -u)" -eq 0 ]]; then
  chown -R "${SUDO_USER}:" "$DEST" 2>/dev/null || true
fi
