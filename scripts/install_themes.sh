#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/themes"
[[ -d "$SRC" ]] || die "Missing themes/"

RELAX="$SRC/Relax-Plasma-Themes"
[[ -d "$RELAX" ]] || RELAX="$SRC"

mkdir -p "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" "${LOCAL_SHARE}/color-schemes"
mkdir -p "${CONFIG_DIR}/Kvantum"

GTK_SRC="$RELAX/Relax GTK Themes"
ICON_SRC="$RELAX/Relax Icons Themes"
KV_SRC="$RELAX/Relax Kvantum Themes"

if [[ -d "$GTK_SRC" ]]; then
  run_quiet "copy GTK themes" rsync -a "$GTK_SRC"/ "${LOCAL_SHARE}/themes/" \
    || die "Could not install GTK themes from: $GTK_SRC"
fi

# Explicit icon packs only (nwg-look / gsettings readable)
for pack in Relax-Dark-Icons Relax-Light-Icons; do
  if [[ -d "$ICON_SRC/$pack" ]]; then
    run_quiet "copy icon pack $pack" rsync -a "$ICON_SRC/$pack"/ "${LOCAL_SHARE}/icons/$pack/" \
      || die "Could not install icons: $ICON_SRC/$pack"
  elif [[ -d "${LOCAL_SHARE}/icons/$pack" ]]; then
    true
  else
    # try find under ICON_SRC
    found="$(find "$ICON_SRC" -maxdepth 2 -type d -name "$pack" 2>/dev/null | head -1 || true)"
    if [[ -n "$found" ]]; then
      run_quiet "copy icon pack $pack" rsync -a "$found"/ "${LOCAL_SHARE}/icons/$pack/" \
        || die "Could not install icons from $found"
    else
      warn "Icon pack not found in repo: $pack (looked under $ICON_SRC)"
    fi
  fi
done

if [[ -d "$KV_SRC" ]]; then
  run_quiet "copy Kvantum themes" rsync -a "$KV_SRC"/ "${CONFIG_DIR}/Kvantum/" \
    || die "Could not install Kvantum from: $KV_SRC"
fi

if [[ -d "$RELAX/Relax Colorschemes" ]]; then
  find "$RELAX/Relax Colorschemes" -type f -name '*.colors' -exec cp -a {} "${LOCAL_SHARE}/color-schemes/" \; 2>/dev/null || true
fi

# Apply dark defaults: Kvantum + GTK + icons
printf '%s\n' '[General]' 'theme=Relax-Kvantum' > "${CONFIG_DIR}/Kvantum/kvantum.kvconfig"
command -v kvantummanager &>/dev/null && kvantummanager --set Relax-Kvantum >/dev/null 2>&1 || true

GTK_THEME="Relax-GTK"
ICON_THEME="Relax-Dark-Icons"
[[ -d "${LOCAL_SHARE}/themes/${GTK_THEME}" ]] || GTK_THEME="$(find "${LOCAL_SHARE}/themes" -maxdepth 1 -type d -name 'Relax*GTK*' ! -name '*Light*' -printf '%f\n' 2>/dev/null | head -1 || true)"
[[ -d "${LOCAL_SHARE}/icons/${ICON_THEME}" ]] || ICON_THEME="Relax-Dark-Icons"

for gtkver in gtk-3.0 gtk-4.0; do
  mkdir -p "${CONFIG_DIR}/${gtkver}"
  cat > "${CONFIG_DIR}/${gtkver}/settings.ini" << EOFINI
[Settings]
gtk-theme-name=${GTK_THEME:-Adwaita-dark}
gtk-icon-theme-name=${ICON_THEME}
gtk-font-name=JetBrainsMono Nerd Font Propo Ultra-Bold 11
gtk-cursor-theme-name=default
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOFINI
done

if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME:-Adwaita-dark}" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
fi

# xsettingsd if present
if [[ -f "${CONFIG_DIR}/xsettingsd/xsettingsd.conf" ]]; then
  sed -i "s/Net\/ThemeName.*/Net\/ThemeName \"${GTK_THEME:-Adwaita-dark}\"/" "${CONFIG_DIR}/xsettingsd/xsettingsd.conf" 2>/dev/null || true
  sed -i "s/Net\/IconThemeName.*/Net\/IconThemeName \"${ICON_THEME}\"/" "${CONFIG_DIR}/xsettingsd/xsettingsd.conf" 2>/dev/null || true
fi
