#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/themes"
[[ -d "$SRC" ]] || die "Missing themes/"

if [[ -z "$(find "$SRC" -mindepth 1 -type f ! -name 'PLACEHOLDER.txt' 2>/dev/null | head -1)" ]]; then
  warn "themes/ empty — clone Relax-Plasma-Themes into themes/"
  exit 0
fi

mkdir -p "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" "${LOCAL_SHARE}/color-schemes"
mkdir -p "${CONFIG_DIR}/Kvantum"

log "Installing themes from $SRC"

# Standard subfolders if present
for sub in themes icons color-schemes; do
  if [[ -d "$SRC/$sub" ]]; then
    rsync -a "$SRC/$sub"/ "${LOCAL_SHARE}/${sub}/"
    ok "synced themes/$sub → ~/.local/share/$sub"
  fi
done
if [[ -d "$SRC/Kvantum" ]]; then
  rsync -a "$SRC/Kvantum"/ "${CONFIG_DIR}/Kvantum/"
  ok "synced themes/Kvantum"
fi

# Heuristic: top-level theme dirs
while IFS= read -r -d '' d; do
  base="$(basename "$d")"
  if [[ -f "$d/index.theme" || -d "$d/gtk-3.0" || -d "$d/gtk-4.0" ]]; then
    rsync -a "$d"/ "${LOCAL_SHARE}/themes/${base}/"
    ok "GTK → themes/$base"
  elif [[ -f "$d/index.theme" ]] && [[ "$base" == *[Ii]con* || "$base" == *[Ii]cons* ]]; then
    rsync -a "$d"/ "${LOCAL_SHARE}/icons/${base}/"
    ok "Icons → $base"
  fi
done < <(find "$SRC" -mindepth 1 -maxdepth 3 -type d -print0 2>/dev/null)

while IFS= read -r -d '' d; do
  base="$(basename "$d")"
  if find "$d" -maxdepth 2 -name '*.kvconfig' 2>/dev/null | grep -q .; then
    rsync -a "$d"/ "${CONFIG_DIR}/Kvantum/${base}/"
    ok "Kvantum → $base"
  fi
done < <(find "$SRC" -mindepth 1 -maxdepth 3 -type d -print0 2>/dev/null)

find "$SRC" -type f -name '*.colors' -exec cp -a {} "${LOCAL_SHARE}/color-schemes/" \; 2>/dev/null || true

KV_CONF="${CONFIG_DIR}/Kvantum/kvantum.kvconfig"
if [[ ! -f "$KV_CONF" && -d "${CONFIG_DIR}/Kvantum/Relax-Kvantum" ]]; then
  printf '%s\n' '[General]' 'theme=Relax-Kvantum' > "$KV_CONF"
  ok "default kvantum.kvconfig"
fi

ok "Theme install finished"
