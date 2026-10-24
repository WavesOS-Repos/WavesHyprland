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
rsync -a --exclude 'PLACEHOLDER.txt' --exclude '.gitkeep' "$SRC"/ "$DEST"/

REQ="$DEST/requirements.txt"
if [[ -f "$REQ" ]]; then
  log "pip install --user -r requirements.txt"
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    sudo -u "$SUDO_USER" pip install --user -r "$REQ" || warn "pip had errors"
  else
    pip install --user -r "$REQ" || warn "pip had errors"
  fi
fi

ok "Wallfliper deployed"
