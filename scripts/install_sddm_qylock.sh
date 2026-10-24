#!/usr/bin/env bash
# Deploy qylock + auto-apply Clockwork orbital (no interactive sddm.sh during install)
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

QYLOCK_SRC="$ROOT/apps/qylock"
USER_QYLOCK="${CONFIG_DIR}/qylock"
SYSTEM_THEMES="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="$SDDM_CONF_DIR/10-waveshyprland.conf"

# Prefer official nested path; fallback if flattened
CLOCKWORK_SRC=""
for candidate in \
  "$QYLOCK_SRC/themes/clockwork/orbital" \
  "$QYLOCK_SRC/themes/clockwork/Orbital" \
  "$QYLOCK_SRC/themes/orbital"
do
  if [[ -d "$candidate" ]]; then
    CLOCKWORK_SRC="$candidate"
    break
  fi
done

log "qylock SDDM"

[[ -d "$QYLOCK_SRC/themes" ]] || { warn "Missing $QYLOCK_SRC/themes"; exit 0; }
[[ -f "$QYLOCK_SRC/sddm.sh" ]] || warn "sddm.sh missing — theme switcher keybind will fail until you add it"

mkdir -p "$USER_QYLOCK"
rsync -a \
  --exclude 'flake.nix' --exclude 'flake.lock' --exclude 'default.nix' \
  --exclude '.github' --exclude 'quickshell-lockscreen' --exclude 'quickshell.sh' \
  --exclude 'qt5.sh' --exclude 'themes-qt5' --exclude 'KEEP_AND_DELETE.txt' \
  "$QYLOCK_SRC"/ "$USER_QYLOCK"/

[[ -f "${USER_QYLOCK}/sddm.sh" ]] && chmod +x "${USER_QYLOCK}/sddm.sh"
ok "Deployed qylock → $USER_QYLOCK"

# Non-interactive: install Clockwork orbital as default (same as sddm.sh would)
if [[ -n "$CLOCKWORK_SRC" ]]; then
  sudo mkdir -p "$SYSTEM_THEMES"
  sudo rm -rf "${SYSTEM_THEMES}/orbital"
  sudo cp -a "$CLOCKWORK_SRC" "${SYSTEM_THEMES}/orbital"
  sudo mkdir -p "$SDDM_CONF_DIR"
  printf '%s\n' '[Theme]' 'Current=orbital' | sudo tee "$SDDM_CONF" >/dev/null
  ok "SDDM theme set: orbital (Clockwork)"
else
  warn "Clockwork orbital not found under apps/qylock/themes — run ~/.config/qylock/sddm.sh once"
fi

log "Later theme switch: ${USER_QYLOCK}/sddm.sh  (Super+Shift+I)"
ok "SDDM qylock done"
