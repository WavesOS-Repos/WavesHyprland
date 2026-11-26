#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/apps/wallfliper"
DEST="${CONFIG_DIR}/wallfliper"

if [[ -z "$(find "$SRC" -type f ! -name 'PLACEHOLDER.txt' ! -name '.gitkeep' 2>/dev/null | head -1)" ]]; then
  warn "apps/wallfliper empty — skip"
  exit 0
fi

log "Deploying Wallfliper → $DEST"
mkdir -p "$DEST"

copy_tree() {
  local from="$1" to="$2"
  mkdir -p "$to"
  if command -v rsync &>/dev/null && rsync --version &>/dev/null 2>&1; then
    rsync -a --exclude 'PLACEHOLDER.txt' --exclude '.gitkeep' "$from"/ "$to"/
  else
    warn "rsync unavailable/broken — using cp"
    (
      cd "$from" || exit 1
      find . -type f \
        ! -name 'PLACEHOLDER.txt' \
        ! -name '.gitkeep' \
        -print0
    ) | while IFS= read -r -d '' rel; do
      rel="${rel#./}"
      mkdir -p "$to/$(dirname "$rel")"
      cp -a "$from/$rel" "$to/$rel"
    done
  fi
}

copy_tree "$SRC" "$DEST"

# Do NOT pip-install requirements on Arch (PySide6 etc. come from pacman/AUR)
ok "Wallfliper deployed"
