#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_arch

PAC="$ROOT/packages/pacman.txt"
AUR="$ROOT/packages/aur.txt"
[[ -f "$PAC" ]] || die "Missing $PAC"

mapfile -t PAC_PKGS < <(grep -vE '^\s*(#|$)' "$PAC")
run_quiet "pacman -S packages" sudo pacman -S --needed --noconfirm "${PAC_PKGS[@]}" \
  || die "pacman package install failed"

mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "$AUR")
if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
  command -v yay &>/dev/null || die "yay missing — run install_yay.sh first"
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    run_quiet "yay -S AUR packages" sudo -u "$SUDO_USER" yay -S --needed --noconfirm "${AUR_PKGS[@]}" \
      || die "AUR package install failed"
  else
    run_quiet "yay -S AUR packages" yay -S --needed --noconfirm "${AUR_PKGS[@]}" \
      || die "AUR package install failed"
  fi
fi
