#!/usr/bin/env bash
# WavesOS system updater — OS + rice (safe) + reset (confirmed)
set -uo pipefail

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
BLU='\033[0;34m'; CYN='\033[0;36m'; RST='\033[0m'; BOLD='\033[1m'

FAILED=()
SUDO_KEEPALIVE_PID=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICE_UPDATE="${SCRIPT_DIR}/rice-update.sh"

banner() {
  clear 2>/dev/null || true
  echo -e "${CYN}${BOLD}"
  echo "  ╔════════════════════════════════════════════╗"
  echo "  ║         WavesOS System Updater             ║"
  echo "  ╚════════════════════════════════════════════╝"
  echo -e "${RST}"
}

finish() {
  [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  pkill -RTMIN+8 waybar 2>/dev/null || true
}
trap finish EXIT

pause_and_exit() {
  echo
  read -r -n 1 -s -p "  Press any key to close..." || true
  echo
}

prepare_sudo() {
  echo -e "${BLU}Administrator authentication required.${RST}"
  echo -e "${YLW}Enter password once; it will be reused.${RST}"
  if ! sudo -v; then
    echo -e "${RED}Authentication failed.${RST}"
    return 1
  fi
  (
    while true; do
      sudo -n -v 2>/dev/null || exit
      sleep 45
    done
  ) &
  SUDO_KEEPALIVE_PID=$!
}

run_step() {
  local label="$1"
  shift
  echo
  echo -e "${CYN}${BOLD}▶ ${label}${RST}"
  if "$@"; then
    echo -e "${GRN}✓ ${label} completed.${RST}"
  else
    local status=$?
    echo -e "${RED}✗ ${label} failed (exit ${status}).${RST}"
    FAILED+=("$label")
  fi
}

has_aur() { command -v yay >/dev/null 2>&1 || command -v paru >/dev/null 2>&1; }
aur_helper() {
  command -v yay >/dev/null 2>&1 && { echo yay; return; }
  command -v paru >/dev/null 2>&1 && { echo paru; return; }
  return 1
}

update_official() { sudo -n pacman -Syu --noconfirm; }
update_aur() {
  local h
  h="$(aur_helper)" || { echo -e "${YLW}No yay/paru; skip AUR.${RST}"; return 1; }
  "$h" -Sua --noconfirm
}
update_everything_arch() {
  local h
  h="$(aur_helper)" || { sudo -n pacman -Syu --noconfirm; return; }
  "$h" -Syu --noconfirm
}
update_flatpak() {
  command -v flatpak >/dev/null 2>&1 || { echo -e "${YLW}Flatpak not installed.${RST}"; return 0; }
  flatpak update --user --assumeyes
  sudo -n flatpak update --system --assumeyes
}
update_hyprpm() {
  command -v hyprpm >/dev/null 2>&1 || { echo -e "${YLW}hyprpm not installed.${RST}"; return 0; }
  hyprpm update
}

count_updates() {
  local official=0 aur=0 fu=0 fs=0
  command -v checkupdates >/dev/null 2>&1 && official="$(checkupdates 2>/dev/null | wc -l | tr -d ' ')" || official=0
  if command -v yay >/dev/null 2>&1; then
    aur="$(yay -Qua 2>/dev/null | wc -l | tr -d ' ')" || aur=0
  elif command -v paru >/dev/null 2>&1; then
    aur="$(paru -Qua 2>/dev/null | wc -l | tr -d ' ')" || aur=0
  fi
  if command -v flatpak >/dev/null 2>&1; then
    fu="$(flatpak remote-ls --updates --user 2>/dev/null | wc -l | tr -d ' ')" || fu=0
    fs="$(flatpak remote-ls --updates --system 2>/dev/null | wc -l | tr -d ' ')" || fs=0
  fi
  printf '%s %s %s %s\n' "$official" "$aur" "$fu" "$fs"
}

run_rice_safe() {
  [[ -x "$RICE_UPDATE" ]] || chmod +x "$RICE_UPDATE" 2>/dev/null || true
  [[ -f "$RICE_UPDATE" ]] || { echo -e "${RED}Missing rice-update.sh${RST}"; return 1; }
  bash "$RICE_UPDATE" safe
}

run_rice_reset() {
  [[ -x "$RICE_UPDATE" ]] || chmod +x "$RICE_UPDATE" 2>/dev/null || true
  [[ -f "$RICE_UPDATE" ]] || { echo -e "${RED}Missing rice-update.sh${RST}"; return 1; }
  bash "$RICE_UPDATE" reset
}

banner

if [[ $EUID -eq 0 ]]; then
  echo -e "${RED}Do not run as root. Use your normal user.${RST}"
  pause_and_exit
  exit 1
fi

echo -e "${BLU}Checking available OS updates…${RST}\n"
read -r OFC AUR FLATPAK_USER FLATPAK_SYSTEM < <(count_updates)

echo -e "  ${BOLD}Official:${RST}        ${YLW}${OFC}${RST}"
echo -e "  ${BOLD}AUR:${RST}             ${YLW}${AUR}${RST}"
echo -e "  ${BOLD}Flatpak user:${RST}    ${YLW}${FLATPAK_USER}${RST}"
echo -e "  ${BOLD}Flatpak system:${RST}  ${YLW}${FLATPAK_SYSTEM}${RST}"
echo
echo -e "${YLW}Choose:${RST}"
echo "  [1] Update everything (OS: Pacman + AUR + Flatpak + Hyprpm)"
echo "  [2] Official packages only"
echo "  [3] AUR packages only"
echo "  [4] Flatpak only"
echo "  [5] Hyprpm only"
echo "  [6] Update rice (safe)     — new features, keep your edits"
echo "  [7] Reset rice             — full stock reinstall (type RESET)"
echo "  [q] Quit"
echo
read -r -p "  Choice: " choice

case "$choice" in
  q|Q) exit 0 ;;
  1|2|3|4|5|6|7) ;;
  *) echo -e "${RED}Invalid choice.${RST}"; pause_and_exit; exit 1 ;;
esac

# sudo for OS ops and rice (packages)
if [[ "$choice" =~ ^[1234567]$ ]]; then
  if ! prepare_sudo; then
    pause_and_exit
    exit 1
  fi
fi

case "$choice" in
  1)
    run_step "Pacman + AUR" update_everything_arch
    run_step "Flatpak" update_flatpak
    run_step "Hyprpm" update_hyprpm
    # rice NOT included
    ;;
  2) run_step "Official packages" update_official ;;
  3) run_step "AUR packages" update_aur ;;
  4) run_step "Flatpak" update_flatpak ;;
  5) run_step "Hyprpm" update_hyprpm ;;
  6) run_step "WavesHyprland rice (safe)" run_rice_safe ;;
  7) run_step "WavesHyprland rice RESET" run_rice_reset ;;
esac

echo
echo -e "${BOLD}────────────────────────────────────────────${RST}"
if ((${#FAILED[@]} == 0)); then
  echo -e "${GRN}${BOLD}✓ Finished successfully.${RST}"
else
  echo -e "${YLW}${BOLD}Finished with ${#FAILED[@]} failed task(s):${RST}"
  printf '  - %s\n' "${FAILED[@]}"
fi

pause_and_exit
