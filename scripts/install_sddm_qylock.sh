#!/usr/bin/env bash
# Deploy qylock; theme apply/switch = upstream sddm.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

QYLOCK_SRC="$ROOT/apps/qylock"
USER_QYLOCK="${CONFIG_DIR}/qylock"

log "qylock SDDM (upstream sddm.sh)"

[[ -d "$QYLOCK_SRC/themes" ]] || { warn "Missing $QYLOCK_SRC/themes"; exit 0; }
[[ -f "$QYLOCK_SRC/sddm.sh" ]] || die "Missing $QYLOCK_SRC/sddm.sh — keep upstream sddm.sh"

mkdir -p "$USER_QYLOCK"
rsync -a \
  --exclude 'flake.nix' --exclude 'flake.lock' --exclude 'default.nix' \
  --exclude '.github' --exclude 'quickshell-lockscreen' --exclude 'quickshell.sh' \
  --exclude 'qt5.sh' --exclude 'themes-qt5' --exclude 'KEEP_AND_DELETE.txt' \
  "$QYLOCK_SRC"/ "$USER_QYLOCK"/

chmod +x "${USER_QYLOCK}/sddm.sh"
ok "Deployed → $USER_QYLOCK"
log "Apply/switch themes: ${USER_QYLOCK}/sddm.sh  (e.g. Super+Shift+I)"
ok "SDDM qylock ready"
