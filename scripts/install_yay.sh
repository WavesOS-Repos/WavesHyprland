#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_arch

if command -v yay &>/dev/null; then
  ok "yay already installed"
  exit 0
fi

log "Installing git + base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log "Cloning yay..."
git clone https://aur.archlinux.org/yay.git "$TMP/yay"
cd "$TMP/yay"

if [[ "$(id -u)" -eq 0 ]]; then
  [[ -n "${SUDO_USER:-}" ]] || die "Do not build yay as root without SUDO_USER"
  chown -R "$SUDO_USER:" "$TMP/yay"
  sudo -u "$SUDO_USER" bash -c "cd '$TMP/yay' && makepkg -si --noconfirm"
else
  makepkg -si --noconfirm
fi

ok "yay installed"
