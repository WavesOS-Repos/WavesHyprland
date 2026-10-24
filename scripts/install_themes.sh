#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/themes"
[[ -d "$SRC" ]] || die "Missing themes/"

# Prefer nested clone path
RELAX="$SRC/Relax-Plasma-Themes"
[[ -d "$RELAX" ]] || RELAX="$SRC"

mkdir -p "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" "${LOCAL_SHARE}/color-schemes"
mkdir -p "${CONFIG_DIR}/Kvantum"

log "Installing Relax themes from $RELAX"

# GTK
if [[ -d "$RELAX/Relax GTK Themes" ]]; then
  rsync -a "$RELAX/Relax GTK Themes"/ "${LOCAL_SHARE}/themes/"
  ok "GTK themes → ~/.local/share/themes"
fi
# Icons
if [[ -d "$RELAX/Relax Icons Themes" ]]; then
  rsync -a "$RELAX/Relax Icons Themes"/ "${LOCAL_SHARE}/icons/"
  ok "Icons → ~/.local/share/icons"
fi
# Kvantum
if [[ -d "$RELAX/Relax Kvantum Themes" ]]; then
  rsync -a "$RELAX/Relax Kvantum Themes"/ "${CONFIG_DIR}/Kvantum/"
  ok "Kvantum → ~/.config/Kvantum"
fi
# Color schemes
if [[ -d "$RELAX/Relax Colorschemes" ]]; then
  find "$RELAX/Relax Colorschemes" -type f -name '*.colors' -exec cp -a {} "${LOCAL_SHARE}/color-schemes/" \;
  ok "Color schemes"
fi

# Fallback: any dir with gtk-3.0 / index.theme under SRC
while IFS= read -r -d '' d; do
  base="$(basename "$d")"
  if [[ -d "$d/gtk-3.0" || -d "$d/gtk-4.0" ]]; then
    rsync -a "$d"/ "${LOCAL_SHARE}/themes/${base}/"
  fi
done < <(find "$RELAX" -mindepth 1 -maxdepth 4 -type d -print0 2>/dev/null)

# Default Kvantum
KV_DARK="Relax-Kvantum"
if [[ -d "${CONFIG_DIR}/Kvantum/${KV_DARK}" ]]; then
  printf '%s\n' '[General]' "theme=${KV_DARK}" > "${CONFIG_DIR}/Kvantum/kvantum.kvconfig"
  ok "kvantum.kvconfig → $KV_DARK"
  command -v kvantummanager &>/dev/null && kvantummanager --set "$KV_DARK" 2>/dev/null || true
fi

# Apply GTK dark defaults (Thunar)
GTK_THEME="Relax-GTK"
ICON_THEME="Relax-Dark-Icons"
# pick first existing if names differ slightly
[[ -d "${LOCAL_SHARE}/themes/${GTK_THEME}" ]] || GTK_THEME="$(find "${LOCAL_SHARE}/themes" -maxdepth 1 -type d -name 'Relax*GTK*' ! -name '*Light*' -printf '%f\n' | head -1 || true)"
[[ -d "${LOCAL_SHARE}/icons/${ICON_THEME}" ]] || ICON_THEME="$(find "${LOCAL_SHARE}/icons" -maxdepth 1 -type d -name 'Relax*Dark*' -printf '%f\n' | head -1 || true)"

for gtkver in gtk-3.0 gtk-4.0; do
  mkdir -p "${CONFIG_DIR}/${gtkver}"
  cat > "${CONFIG_DIR}/${gtkver}/settings.ini" << EOF
[Settings]
gtk-theme-name=${GTK_THEME:-Adwaita-dark}
gtk-icon-theme-name=${ICON_THEME:-Adwaita}
gtk-font-name=JetBrainsMono Nerd Font Propo Ultra-Bold 11
gtk-cursor-theme-name=default
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
done
ok "GTK settings.ini → ${GTK_THEME:-?} / ${ICON_THEME:-?}"

if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME:-Adwaita-dark}" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME:-Adwaita}" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
  ok "gsettings GTK applied"
fi

ok "Theme install + apply finished"
