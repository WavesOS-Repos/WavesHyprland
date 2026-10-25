#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

DEST="${USER_HOME}/Pictures/Wallpapers"
REPO="https://github.com/WavesOS-Repos/WavesWallpapers.git"

mkdir -p "${USER_HOME}/Pictures"

if [[ -d "$DEST/.git" ]]; then
  run_quiet "git pull Wallpapers" git -C "$DEST" pull --ff-only \
    || die "git pull failed for $DEST"
elif [[ -d "$DEST" ]] && [[ -n "$(ls -A "$DEST" 2>/dev/null || true)" ]]; then
  warn "$DEST exists but is not a git repo — leave as-is"
else
  rm -rf "$DEST"
  run_quiet "git clone WavesWallpapers" git clone --depth 1 "$REPO" "$DEST" \
    || die "git clone failed: $REPO → $DEST (check network / git)"
fi

if [[ -n "${SUDO_USER:-}" && "$(id -u)" -eq 0 ]]; then
  chown -R "${SUDO_USER}:" "${USER_HOME}/Pictures" 2>/dev/null || true
fi

# Verify not empty
if [[ -z "$(ls -A "$DEST" 2>/dev/null || true)" ]]; then
  die "Wallpapers directory is empty after install: $DEST"
fi
