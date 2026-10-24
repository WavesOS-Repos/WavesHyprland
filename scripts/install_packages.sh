#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_arch

PAC="$ROOT/packages/pacman.txt"
AUR="$ROOT/packages/aur.txt"
[[ -f "$PAC" ]] || die "Missing $PAC"

mapfile -t PAC_PKGS < <(grep -vE '^\s*(#|$)' "$PAC")
log "Installing official packages (${#PAC_PKGS[@]})..."
sudo pacman -S --needed --noconfirm "${PAC_PKGS[@]}"
ok "pacman packages done"

mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "$AUR")
if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
  command -v yay &>/dev/null || die "yay missing — run install_yay.sh first"
  log "Installing AUR packages (${#AUR_PKGS[@]})..."
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    sudo -u "$SUDO_USER" yay -S --needed --noconfirm "${AUR_PKGS[@]}"
  else
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
  fi
  ok "AUR packages done"
fi

ok "All packages installed"
