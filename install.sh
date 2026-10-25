#!/usr/bin/env bash
# WavesHyprland installer — main entry (quiet)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WAVES_QUIET="${WAVES_QUIET:-1}"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/scripts/common.sh"

run_step() {
  local name="$1"
  if ! bash "$ROOT/scripts/$name"; then
    die "Step failed: $name"
  fi
}

# Keep sudo alive so password is asked only once
sudo_keep_alive() {
  # Ask once up front
  if ! sudo -v; then
    die "sudo authentication failed"
  fi
  # Refresh ticket in background until installer exits
  (
    while true; do
      sudo -n true 2>/dev/null || exit 0
      sleep 30
    done
  ) &
  SUDO_KEEP_ALIVE_PID=$!
  trap 'kill "${SUDO_KEEP_ALIVE_PID}" 2>/dev/null || true' EXIT
}

full_install() {
  show_logo
  require_arch
  sudo_keep_alive
  echo "Installing WavesHyprland (quiet)…"
  echo

  run_step install_yay.sh
  run_step install_packages.sh
  run_step backup_configs.sh
  run_step deploy_configs.sh
  run_step deploy_wallfliper.sh
  run_step install_wallpapers.sh
  run_step install_themes.sh
  run_step install_sddm_qylock.sh
  run_step post_setup.sh

  echo
  if [[ -t 1 ]]; then
    printf '\033[1m\033[32m'
  fi
  echo "  Install finished."
  if [[ -t 1 ]]; then
    printf '\033[0m'
  fi
  echo "  Backup: $(cat /tmp/waveshyprland-last-backup 2>/dev/null || echo n/a)"
  echo

  if [[ -t 1 ]]; then
    printf '\033[1m\033[31m'
  fi
  cat << 'REBOOT'

  ╔══════════════════════════════════════════════════════════╗
  ║                                                          ║
  ║   PLEASE REBOOT YOUR PC MANUALLY TO FINISH SETUP         ║
  ║                                                          ║
  ║   Run:   sudo reboot                                     ║
  ║                                                          ║
  ╚══════════════════════════════════════════════════════════╝

REBOOT
  if [[ -t 1 ]]; then
    printf '\033[0m\n'
  fi
}

usage() {
  cat << EOFU
WavesHyprland installer v$(cat "$ROOT/VERSION" 2>/dev/null || echo 0)

  (no args)     Menu
  --all         Full install
  --yay --packages --backup --configs --wallfliper
  --wallpapers  Clone WavesWallpapers → ~/Pictures/Wallpapers
  --themes --sddm --post
  WAVES_QUIET=0 ./install.sh --all   # verbose logs
EOFU
}

menu() {
  show_logo
  echo "  1) Full install"
  echo "  2) Install yay"
  echo "  3) Install packages"
  echo "  4) Backup configs"
  echo "  5) Deploy configs"
  echo "  6) Deploy Wallfliper"
  echo "  7) Install wallpapers"
  echo "  8) Install themes"
  echo "  9) Install SDDM qylock"
  echo " 10) Post-setup"
  echo "  0) Exit"
  read -r -p "Choice: " c
  case "$c" in
    1) full_install ;;
    2) run_step install_yay.sh ;;
    3) run_step install_packages.sh ;;
    4) run_step backup_configs.sh ;;
    5) run_step deploy_configs.sh ;;
    6) run_step deploy_wallfliper.sh ;;
    7) run_step install_wallpapers.sh ;;
    8) run_step install_themes.sh ;;
    9) run_step install_sddm_qylock.sh ;;
    10) run_step post_setup.sh ;;
    0) exit 0 ;;
    *) die "Invalid choice" ;;
  esac
}

case "${1:-}" in
  "") menu ;;
  --all) full_install ;;
  --yay) run_step install_yay.sh ;;
  --packages) run_step install_packages.sh ;;
  --backup) run_step backup_configs.sh ;;
  --configs) run_step deploy_configs.sh ;;
  --wallfliper) run_step deploy_wallfliper.sh ;;
  --wallpapers) run_step install_wallpapers.sh ;;
  --themes) run_step install_themes.sh ;;
  --sddm) run_step install_sddm_qylock.sh ;;
  --post) run_step post_setup.sh ;;
  -h|--help) usage ;;
  *) usage; die "Unknown: $1" ;;
esac
