#!/usr/bin/env bash
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_arch

PAC="$ROOT/packages/pacman.txt"
AUR="$ROOT/packages/aur.txt"
[[ -f "$PAC" ]] || die "Missing $PAC"

is_installed() {
  pacman -Q "$1" &>/dev/null
}

install_one_pacman() {
  local pkg="$1"
  if is_installed "$pkg"; then
    ok "skip (installed): $pkg"
    return 0
  fi
  log "install: $pkg"
  if sudo pacman -S --needed --noconfirm "$pkg"; then
    ok "installed: $pkg"
    return 0
  fi
  warn "failed: $pkg"
  return 1
}

install_one_aur() {
  local pkg="$1"
  if is_installed "$pkg"; then
    ok "skip (installed): $pkg"
    return 0
  fi
  log "install (AUR): $pkg"
  local rc=0
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    sudo -u "$SUDO_USER" yay -S --needed --noconfirm "$pkg" || rc=$?
  else
    yay -S --needed --noconfirm "$pkg" || rc=$?
  fi
  if [[ $rc -eq 0 ]]; then
    ok "installed: $pkg"
    return 0
  fi
  warn "failed: $pkg"
  return 1
}

# --- official ---
mapfile -t PAC_PKGS < <(grep -vE '^\s*(#|$)' "$PAC" | sed 's/[[:space:]]*$//')
log "Official packages: ${#PAC_PKGS[@]}"
PAC_OK=0
PAC_SKIP=0
PAC_FAIL=0
FAILED_PAC=()

for pkg in "${PAC_PKGS[@]}"; do
  [[ -z "$pkg" ]] && continue
  if is_installed "$pkg"; then
    ok "skip (installed): $pkg"
    ((PAC_SKIP++)) || true
    continue
  fi
  if install_one_pacman "$pkg"; then
    ((PAC_OK++)) || true
  else
    ((PAC_FAIL++)) || true
    FAILED_PAC+=("$pkg")
  fi
done

ok "pacman: installed=$PAC_OK skipped=$PAC_SKIP failed=$PAC_FAIL"
if (( PAC_FAIL > 0 )); then
  warn "Failed official packages: ${FAILED_PAC[*]}"
fi

# --- AUR ---
if [[ ! -f "$AUR" ]]; then
  warn "No $AUR — skip AUR"
  exit 0
fi

mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "$AUR" | sed 's/[[:space:]]*$//')
if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
  ok "No AUR packages listed"
  exit 0
fi

command -v yay &>/dev/null || die "yay missing — run install_yay.sh first"

log "AUR packages: ${#AUR_PKGS[@]}"
AUR_OK=0
AUR_SKIP=0
AUR_FAIL=0
FAILED_AUR=()

for pkg in "${AUR_PKGS[@]}"; do
  [[ -z "$pkg" ]] && continue
  if is_installed "$pkg"; then
    ok "skip (installed): $pkg"
    ((AUR_SKIP++)) || true
    continue
  fi
  if install_one_aur "$pkg"; then
    ((AUR_OK++)) || true
  else
    ((AUR_FAIL++)) || true
    FAILED_AUR+=("$pkg")
  fi
done

ok "AUR: installed=$AUR_OK skipped=$AUR_SKIP failed=$AUR_FAIL"
if (( AUR_FAIL > 0 )); then
  warn "Failed AUR packages: ${FAILED_AUR[*]}"
fi

if (( PAC_FAIL + AUR_FAIL > 0 )); then
  warn "Some packages failed — installer continues; fix names or install manually."
  exit 0
fi

ok "All packages processed"
