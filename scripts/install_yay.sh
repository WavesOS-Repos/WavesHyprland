#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_arch

if command -v yay &>/dev/null; then
  exit 0
fi

errf="$(mktemp)"
if ! sudo pacman -S --needed --noconfirm git base-devel >"$errf" 2>&1; then
  err "FAILED: install git base-devel"
  sed 's/^/    /' "$errf" >&2
  rm -f "$errf"
  die "Could not install git/base-devel"
fi
rm -f "$errf"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

errf="$(mktemp)"
if ! git clone https://aur.archlinux.org/yay.git "$TMP/yay" >"$errf" 2>&1; then
  err "FAILED: clone yay"
  sed 's/^/    /' "$errf" >&2
  rm -f "$errf"
  die "Could not clone yay AUR repo"
fi
rm -f "$errf"

cd "$TMP/yay"
errf="$(mktemp)"
if [[ "$(id -u)" -eq 0 ]]; then
  [[ -n "${SUDO_USER:-}" ]] || die "Do not build yay as root without SUDO_USER"
  chown -R "$SUDO_USER:" "$TMP/yay"
  if ! sudo -u "$SUDO_USER" bash -c "cd '$TMP/yay' && makepkg -si --noconfirm" >"$errf" 2>&1; then
    err "FAILED: makepkg yay"
    sed 's/^/    /' "$errf" >&2
    rm -f "$errf"
    die "yay build/install failed"
  fi
else
  if ! makepkg -si --noconfirm >"$errf" 2>&1; then
    err "FAILED: makepkg yay"
    sed 's/^/    /' "$errf" >&2
    rm -f "$errf"
    die "yay build/install failed"
  fi
fi
rm -f "$errf"
