#!/usr/bin/env bash
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_arch

PAC="$ROOT/packages/pacman.txt"
AUR="$ROOT/packages/aur.txt"
[[ -f "$PAC" ]] || die "Missing $PAC"

failed=0

install_one_pacman() {
  local pkg="$1"
  local errf
  errf="$(mktemp)"
  if sudo pacman -S --needed --noconfirm "$pkg" >"$errf" 2>&1; then
    rm -f "$errf"
    return 0
  fi
  err "pacman failed: $pkg"
  sed 's/^/    /' "$errf" >&2
  rm -f "$errf"
  failed=1
  return 1
}

install_one_aur() {
  local pkg="$1"
  local errf
  errf="$(mktemp)"
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    if sudo -u "$SUDO_USER" yay -S --needed --noconfirm "$pkg" >"$errf" 2>&1; then
      rm -f "$errf"
      return 0
    fi
  else
    if yay -S --needed --noconfirm "$pkg" >"$errf" 2>&1; then
      rm -f "$errf"
      return 0
    fi
  fi
  err "yay failed: $pkg"
  sed 's/^/    /' "$errf" >&2
  rm -f "$errf"
  failed=1
  return 1
}

mapfile -t PAC_PKGS < <(grep -vE '^\s*(#|$)' "$PAC")
for pkg in "${PAC_PKGS[@]}"; do
  install_one_pacman "$pkg" || true
done

mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "$AUR" 2>/dev/null || true)
if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
  command -v yay &>/dev/null || die "yay missing — run install_yay.sh first"
  for pkg in "${AUR_PKGS[@]}"; do
    install_one_aur "$pkg" || true
  done
fi

# Hard requirements for EWW stack
for need in eww cava python jq curl; do
  if ! command -v "$need" &>/dev/null && ! pacman -Q "$need" &>/dev/null; then
    err "Missing required tool after install: $need"
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  warn "Some packages failed (see above). Install continued; fix missing pkgs manually if needed."
fi
exit 0
