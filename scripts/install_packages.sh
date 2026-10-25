#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_arch

PAC="$ROOT/packages/pacman.txt"
AUR="$ROOT/packages/aur.txt"
[[ -f "$PAC" ]] || die "Missing $PAC"

mapfile -t PAC_PKGS < <(grep -vE '^\s*(#|$)' "$PAC")
# force full silence for pacman
errf="$(mktemp)"
if ! sudo pacman -S --needed --noconfirm "${PAC_PKGS[@]}" >"$errf" 2>&1; then
  err "FAILED: pacman install"
  sed 's/^/    /' "$errf" >&2
  rm -f "$errf"
  die "pacman package install failed"
fi
rm -f "$errf"

mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "$AUR")
if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
  exit 0
fi
command -v yay &>/dev/null || die "yay missing — run install_yay.sh first"

errf="$(mktemp)"
if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
  if ! sudo -u "$SUDO_USER" yay -S --needed --noconfirm "${AUR_PKGS[@]}" >"$errf" 2>&1; then
    err "FAILED: yay install"
    sed 's/^/    /' "$errf" >&2
    rm -f "$errf"
    die "AUR package install failed"
  fi
else
  if ! yay -S --needed --noconfirm "${AUR_PKGS[@]}" >"$errf" 2>&1; then
    err "FAILED: yay install"
    sed 's/^/    /' "$errf" >&2
    rm -f "$errf"
    die "AUR package install failed"
  fi
fi
rm -f "$errf"
