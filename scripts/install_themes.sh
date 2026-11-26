#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/themes"
[[ -d "$SRC" ]] || die "Missing themes/"

if [[ -z "$(find "$SRC" -mindepth 1 -type f ! -name 'PLACEHOLDER.txt' 2>/dev/null | head -1)" ]]; then
  warn "themes/ empty — put Relax GTK / Icons / Kvantum under themes/"
  exit 0
fi

mkdir -p "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" "${LOCAL_SHARE}/color-schemes"
mkdir -p "${CONFIG_DIR}/Kvantum"
mkdir -p "${USER_HOME}/.icons" "${USER_HOME}/.themes"

# rsync if healthy, else cp -a
copy_tree() {
  local from="$1" to="$2"
  [[ -d "$from" ]] || return 0
  mkdir -p "$to"
  if command -v rsync &>/dev/null && rsync --version &>/dev/null 2>&1; then
    rsync -a "$from"/ "$to"/
  else
    warn "rsync unavailable/broken — using cp ($from → $to)"
    cp -a "$from"/. "$to"/
  fi
}

log "Installing themes from $SRC"

# --- Relax-Plasma-Themes layout ---
RELAX="$SRC/Relax-Plasma-Themes"
if [[ -d "$RELAX" ]]; then
  # GTK
  if [[ -d "$RELAX/Relax GTK Themes" ]]; then
    for d in "$RELAX/Relax GTK Themes"/*/; do
      [[ -d "$d" ]] || continue
      base="$(basename "$d")"
      copy_tree "$d" "${LOCAL_SHARE}/themes/${base}"
      copy_tree "$d" "${USER_HOME}/.themes/${base}"
      ok "GTK → $base"
    done
  fi

  # Icons — remove old copies then install (matches your preferred method)
  if [[ -d "$RELAX/Relax Icons Themes" ]]; then
    rm -rf "${LOCAL_SHARE}/icons/Relax-Dark-Icons" "${LOCAL_SHARE}/icons/Relax-Light-Icons" 2>/dev/null || true
    rm -rf "${USER_HOME}/.icons/Relax-Dark-Icons" "${USER_HOME}/.icons/Relax-Light-Icons" 2>/dev/null || true
    for d in "$RELAX/Relax Icons Themes"/*/; do
      [[ -d "$d" ]] || continue
      base="$(basename "$d")"
      copy_tree "$d" "${LOCAL_SHARE}/icons/${base}"
      copy_tree "$d" "${USER_HOME}/.icons/${base}"
      ok "Icons → $base"
    done
  fi

  # Kvantum
  if [[ -d "$RELAX/Relax Kvantum Themes" ]]; then
    for d in "$RELAX/Relax Kvantum Themes"/*/; do
      [[ -d "$d" ]] || continue
      base="$(basename "$d")"
      copy_tree "$d" "${CONFIG_DIR}/Kvantum/${base}"
      ok "Kvantum → $base"
    done
  fi
fi

# --- Generic top-level themes/icons/Kvantum if present ---
for sub in themes icons color-schemes; do
  if [[ -d "$SRC/$sub" ]]; then
    copy_tree "$SRC/$sub" "${LOCAL_SHARE}/${sub}"
    ok "synced themes/$sub"
  fi
done
if [[ -d "$SRC/Kvantum" ]]; then
  copy_tree "$SRC/Kvantum" "${CONFIG_DIR}/Kvantum"
  ok "synced themes/Kvantum"
fi

# Heuristic: any leftover GTK / icon dirs under themes/
while IFS= read -r -d '' d; do
  base="$(basename "$d")"
  case "$base" in
    Relax-Plasma-Themes|Relax\ GTK\ Themes|Relax\ Icons\ Themes|Relax\ Kvantum\ Themes) continue ;;
  esac
  if [[ -d "$d/gtk-3.0" || -d "$d/gtk-4.0" ]]; then
    copy_tree "$d" "${LOCAL_SHARE}/themes/${base}"
    ok "GTK → $base"
  elif [[ -f "$d/index.theme" ]] && [[ "$base" == *[Ii]con* ]]; then
    copy_tree "$d" "${LOCAL_SHARE}/icons/${base}"
    ok "Icons → $base"
  elif find "$d" -maxdepth 2 -name '*.kvconfig' 2>/dev/null | grep -q .; then
    copy_tree "$d" "${CONFIG_DIR}/Kvantum/${base}"
    ok "Kvantum → $base"
  fi
done < <(find "$SRC" -mindepth 1 -maxdepth 3 -type d -print0 2>/dev/null)

find "$SRC" -type f -name '*.colors' -exec cp -a {} "${LOCAL_SHARE}/color-schemes/" \; 2>/dev/null || true

# Default Kvantum theme
KV_CONF="${CONFIG_DIR}/Kvantum/kvantum.kvconfig"
if [[ -d "${CONFIG_DIR}/Kvantum/Relax-Kvantum" ]]; then
  printf '%s\n' '[General]' 'theme=Relax-Kvantum' > "$KV_CONF"
  ok "default kvantum.kvconfig → Relax-Kvantum"
fi

# Ownership if installer ran with sudo
if [[ -n "${SUDO_USER:-}" ]]; then
  chown -R "${SUDO_USER}:${SUDO_USER}" \
    "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" \
    "${USER_HOME}/.themes" "${USER_HOME}/.icons" \
    "${CONFIG_DIR}/Kvantum" 2>/dev/null || true
fi

ok "Theme install finished"
