#!/usr/bin/env bash
# WavesHyprland installer — main entry
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/scripts/common.sh"

run_step() {
  bash "$ROOT/scripts/$1"
}

full_install() {
  show_logo
  log "Full WavesHyprland install"
  require_arch
  run_step install_yay.sh
  run_step install_packages.sh
  run_step backup_configs.sh
  run_step deploy_configs.sh
  run_step deploy_wallfliper.sh
  run_step install_themes.sh
  run_step install_sddm_qylock.sh
  run_step post_setup.sh

  echo
  ok "=== Install finished ==="
  log "Backup: $(cat /tmp/waveshyprland-last-backup 2>/dev/null || echo n/a)"
  echo
  echo "  After reboot:"
  echo "    • Log into Hyprland"
  echo "    • Super+W  wallpaper (python ~/.config/wallfliper/main.py)"
  echo "    • Super+T  theme · Super+H  keybinds"
  echo "    • Super+Shift+I  SDDM theme (sddm.sh)"
  echo

  if [[ -t 1 ]]; then
    printf '\n\033[1m\033[31m'
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
  cat << EOF
WavesHyprland installer v$(cat "$ROOT/VERSION" 2>/dev/null || echo 0)

  (no args)     Menu
  --all         Full install
  --yay         Install yay
  --packages    All packages
  --backup      Backup dots
  --configs     Deploy configs/
  --wallfliper  Deploy Wallfliper
  --themes      Relax themes
  --sddm        qylock SDDM
  --post        Post-setup
  -h --help     Help
EOF
}

menu() {
  show_logo
  echo "  1) Full install"
  echo "  2) Install yay"
  echo "  3) Install packages"
  echo "  4) Backup configs"
  echo "  5) Deploy configs"
  echo "  6) Deploy Wallfliper"
  echo "  7) Install themes"
  echo "  8) Install SDDM qylock"
  echo "  9) Post-setup"
  echo "  0) Exit"
  read -r -p "Choice: " c
  case "$c" in
    1) full_install ;;
    2) run_step install_yay.sh ;;
    3) run_step install_packages.sh ;;
    4) run_step backup_configs.sh ;;
    5) run_step deploy_configs.sh ;;
    6) run_step deploy_wallfliper.sh ;;
    7) run_step install_themes.sh ;;
    8) run_step install_sddm_qylock.sh ;;
    9) run_step post_setup.sh ;;
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
  --themes) run_step install_themes.sh ;;
  --sddm) run_step install_sddm_qylock.sh ;;
  --post) run_step post_setup.sh ;;
  -h|--help) usage ;;
  *) usage; die "Unknown: $1" ;;
esac
