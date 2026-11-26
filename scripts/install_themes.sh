#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/themes"
[[ -d "$SRC" ]] || die "Missing themes/ directory at $SRC"

RELAX="$SRC/Relax-Plasma-Themes"
[[ -d "$RELAX" ]] || RELAX="$SRC"

mkdir -p "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" "${LOCAL_SHARE}/color-schemes"
mkdir -p "${CONFIG_DIR}/Kvantum"
mkdir -p "${USER_HOME}/.icons" "${USER_HOME}/.themes"

copy_tree() {
  local from="$1" to="$2"
  [[ -d "$from" ]] || return 0
  mkdir -p "$to"
  if command -v rsync &>/dev/null && rsync --version &>/dev/null 2>&1; then
    rsync -a "$from"/ "$to"/
  else
    warn "rsync unavailable/broken — using cp"
    cp -a "$from"/. "$to"/
  fi
}

GTK_SRC=""
for cand in "$RELAX/Relax GTK Themes" "$RELAX/Relax GTK Theme"; do
  [[ -d "$cand" ]] && GTK_SRC="$cand" && break
done

ICON_SRC=""
for cand in "$RELAX/Relax Icons Themes" "$RELAX/Relax Icon Themes"; do
  [[ -d "$cand" ]] && ICON_SRC="$cand" && break
done

KV_SRC=""
for cand in "$RELAX/Relax Kvantum Themes" "$RELAX/Relax Kvantum Theme"; do
  [[ -d "$cand" ]] && KV_SRC="$cand" && break
done

# --- GTK ---
if [[ -n "$GTK_SRC" ]]; then
  for d in "$GTK_SRC"/*/; do
    [[ -d "$d" ]] || continue
    base="$(basename "$d")"
    copy_tree "$d" "${LOCAL_SHARE}/themes/${base}"
    copy_tree "$d" "${USER_HOME}/.themes/${base}"
  done
  ok "GTK themes installed"
else
  warn "GTK themes folder not found under $RELAX"
fi

# --- Kvantum ---
if [[ -n "$KV_SRC" ]]; then
  for d in "$KV_SRC"/*/; do
    [[ -d "$d" ]] || continue
    base="$(basename "$d")"
    copy_tree "$d" "${CONFIG_DIR}/Kvantum/${base}"
  done
  ok "Kvantum themes installed"
else
  warn "Kvantum themes folder not found under $RELAX"
fi

if [[ -d "$RELAX/Relax Colorschemes" ]]; then
  find "$RELAX/Relax Colorschemes" -type f -name '*.colors' \
    -exec cp -a {} "${LOCAL_SHARE}/color-schemes/" \; 2>/dev/null || true
fi

# Default Kvantum + GTK (dark)
printf '%s\n' '[General]' 'theme=Relax-Kvantum' > "${CONFIG_DIR}/Kvantum/kvantum.kvconfig"
command -v kvantummanager &>/dev/null && kvantummanager --set Relax-Kvantum >/dev/null 2>&1 || true

GTK_THEME="Relax-GTK"
ICON_THEME="Relax-Dark-Icons"
[[ -d "${LOCAL_SHARE}/themes/${GTK_THEME}" ]] || \
  GTK_THEME="$(find "${LOCAL_SHARE}/themes" -maxdepth 1 -type d -name 'Relax*GTK*' ! -name '*Light*' -printf '%f\n' 2>/dev/null | head -1 || echo Adwaita-dark)"

for gtkver in gtk-3.0 gtk-4.0; do
  mkdir -p "${CONFIG_DIR}/${gtkver}"
  cat > "${CONFIG_DIR}/${gtkver}/settings.ini" << EOFINI
[Settings]
gtk-theme-name=${GTK_THEME}
gtk-icon-theme-name=${ICON_THEME}
gtk-font-name=JetBrainsMono Nerd Font Propo Ultra-Bold 11
gtk-cursor-theme-name=default
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOFINI
done

if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
fi

# --- Icons LAST: remove then copy ---
if [[ -n "$ICON_SRC" ]]; then
  rm -rf "${LOCAL_SHARE}/icons/Relax-Dark-Icons" "${LOCAL_SHARE}/icons/Relax-Light-Icons" 2>/dev/null || true
  rm -rf "${USER_HOME}/.icons/Relax-Dark-Icons" "${USER_HOME}/.icons/Relax-Light-Icons" 2>/dev/null || true
  for d in "$ICON_SRC"/*/; do
    [[ -d "$d" ]] || continue
    base="$(basename "$d")"
    copy_tree "$d" "${LOCAL_SHARE}/icons/${base}"
    copy_tree "$d" "${USER_HOME}/.icons/${base}"
  done
  ok "Icon packs installed"
else
  warn "Icon themes folder not found under $RELAX"
fi

if [[ -n "${SUDO_USER:-}" ]]; then
  chown -R "${SUDO_USER}:${SUDO_USER}" \
    "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" \
    "${USER_HOME}/.themes" "${USER_HOME}/.icons" \
    "${CONFIG_DIR}/Kvantum" 2>/dev/null || true
fi

ok "Theme install finished"
