#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

SRC="$ROOT/themes"
[[ -d "$SRC" ]] || die "Missing themes/ directory at $SRC"

RELAX="$SRC/Relax-Plasma-Themes"
[[ -d "$RELAX" ]] || RELAX="$SRC"

mkdir -p "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" "${LOCAL_SHARE}/color-schemes"
mkdir -p "${USER_HOME}/.icons"
mkdir -p "${CONFIG_DIR}/Kvantum"

GTK_SRC=""
for cand in "$RELAX/Relax GTK Themes" "$RELAX/Relax GTK Theme"; do
  [[ -d "$cand" ]] && GTK_SRC="$cand" && break
done

ICON_SRC=""
for cand in "$RELAX/Relax Icons Themes" "$RELAX/Relax Icon Themes" "$RELAX/Relax Icons Theme"; do
  [[ -d "$cand" ]] && ICON_SRC="$cand" && break
done

KV_SRC=""
for cand in "$RELAX/Relax Kvantum Themes" "$RELAX/Relax Kvantum Theme"; do
  [[ -d "$cand" ]] && KV_SRC="$cand" && break
done

# GTK
if [[ -n "$GTK_SRC" ]]; then
  run_quiet "install GTK themes" rsync -a "$GTK_SRC"/ "${LOCAL_SHARE}/themes/" \
    || die "GTK theme copy failed from: $GTK_SRC"
else
  warn "GTK themes folder not found under $RELAX"
fi

# Icons: remove old packs, copy into ~/.local/share/icons AND ~/.icons
rm -rf \
  "${LOCAL_SHARE}/icons/Relax-Dark-Icons" \
  "${LOCAL_SHARE}/icons/Relax-Light-Icons" \
  "${USER_HOME}/.icons/Relax-Dark-Icons" \
  "${USER_HOME}/.icons/Relax-Light-Icons"

if [[ -n "$ICON_SRC" ]]; then
  # copy every pack directory inside icon source
  shopt -s nullglob
  packs=()
  for d in "$ICON_SRC"/*/; do
    [[ -d "$d" ]] && packs+=("$d")
  done
  if [[ ${#packs[@]} -eq 0 ]]; then
    die "No icon pack folders inside: $ICON_SRC"
  fi
  for d in "${packs[@]}"; do
    name="$(basename "$d")"
    run_quiet "install icons $name → .local/share/icons" rsync -a "$d" "${LOCAL_SHARE}/icons/${name}/" \
      || die "Failed copying icons to ~/.local/share/icons/$name"
    run_quiet "install icons $name → .icons" rsync -a "$d" "${USER_HOME}/.icons/${name}/" \
      || die "Failed copying icons to ~/.icons/$name"
  done
  shopt -u nullglob
else
  die "Icon themes folder not found (tried 'Relax Icons Themes' / 'Relax Icon Themes') under $RELAX"
fi

# Kvantum
if [[ -n "$KV_SRC" ]]; then
  run_quiet "install Kvantum themes" rsync -a "$KV_SRC"/ "${CONFIG_DIR}/Kvantum/" \
    || die "Kvantum copy failed from: $KV_SRC"
else
  warn "Kvantum themes folder not found under $RELAX"
fi

if [[ -d "$RELAX/Relax Colorschemes" ]]; then
  find "$RELAX/Relax Colorschemes" -type f -name '*.colors' -exec cp -a {} "${LOCAL_SHARE}/color-schemes/" \; 2>/dev/null || true
fi

# Ownership
if [[ -n "${SUDO_USER:-}" && "$(id -u)" -eq 0 ]]; then
  chown -R "${SUDO_USER}:" "${LOCAL_SHARE}/themes" "${LOCAL_SHARE}/icons" "${USER_HOME}/.icons" "${CONFIG_DIR}/Kvantum" 2>/dev/null || true
fi

# Force DARK application
printf '%s\n' '[General]' 'theme=Relax-Kvantum' > "${CONFIG_DIR}/Kvantum/kvantum.kvconfig"
command -v kvantummanager &>/dev/null && kvantummanager --set Relax-Kvantum >/dev/null 2>&1 || true

GTK_THEME="Relax-GTK"
ICON_THEME="Relax-Dark-Icons"
[[ -d "${LOCAL_SHARE}/themes/${GTK_THEME}" ]] || \
  GTK_THEME="$(find "${LOCAL_SHARE}/themes" -maxdepth 1 -type d -name 'Relax*GTK*' ! -name '*Light*' -printf '%f\n' 2>/dev/null | head -1 || echo Adwaita-dark)"
[[ -d "${LOCAL_SHARE}/icons/${ICON_THEME}" ]] || \
  [[ -d "${USER_HOME}/.icons/${ICON_THEME}" ]] || ICON_THEME="Adwaita"

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
