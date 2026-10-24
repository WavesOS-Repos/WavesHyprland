#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

TARGETS=(
  hypr waybar rofi wlogout kitty matugen gtk-3.0 gtk-4.0
  Thunar qt6ct nwg-look xsettingsd qylock cava btop fontconfig
  wallfliper conky
)

mkdir -p "$BACKUP_ROOT"
log "Backing up to $BACKUP_ROOT"

for name in "${TARGETS[@]}"; do
  src="${CONFIG_DIR}/${name}"
  if [[ -e "$src" ]]; then
    cp -a "$src" "$BACKUP_ROOT/"
    ok "backed up $name"
  fi
done

for f in mimeapps.list kdeglobals; do
  if [[ -f "${CONFIG_DIR}/${f}" ]]; then
    cp -a "${CONFIG_DIR}/${f}" "$BACKUP_ROOT/"
    ok "backed up $f"
  fi
done

if [[ -d "${USER_HOME}/.conky" ]]; then
  cp -a "${USER_HOME}/.conky" "$BACKUP_ROOT/dot-conky"
  ok "backed up ~/.conky"
fi

echo "$BACKUP_ROOT" > /tmp/waveshyprland-last-backup
ok "Backup complete: $BACKUP_ROOT"
