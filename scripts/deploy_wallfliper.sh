#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/apps/wallfliper"
DEST="${CONFIG_DIR}/wallfliper"

if [[ -z "$(find "$SRC" -type f ! -name 'PLACEHOLDER.txt' ! -name '.gitkeep' 2>/dev/null | head -1)" ]]; then
  warn "apps/wallfliper empty — skip"
  exit 0
fi

mkdir -p "$DEST"
run_quiet "deploy wallfliper" rsync -a --exclude 'PLACEHOLDER.txt' --exclude '.gitkeep' "$SRC"/ "$DEST"/ \
  || die "Failed to deploy Wallfliper to $DEST"

# Do NOT pip install requirements.txt (Arch/system packages only)
