#!/usr/bin/env bash
# sysupdate.sh — interactive system updater (run inside Kitty)

set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
RST='\033[0m'
BOLD='\033[1m'

banner() {
  clear
  echo -e "${CYN}${BOLD}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║         System Updater               ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${RST}"
}

count_updates() {
  local ofc=0 aur=0
  ofc=$(checkupdates 2>/dev/null | wc -l) || ofc=0
  if command -v yay &>/dev/null; then
    aur=$(yay -Qua 2>/dev/null | wc -l) || aur=0
  elif command -v paru &>/dev/null; then
    aur=$(paru -Qua 2>/dev/null | wc -l) || aur=0
  fi
  echo "$ofc" "$aur"
}

banner
echo -e "${BLU}Refreshing package databases...${RST}\n"

if command -v yay &>/dev/null; then
  yay -Sy --noconfirm 2>/dev/null || true
elif command -v paru &>/dev/null; then
  paru -Sy --noconfirm 2>/dev/null || true
else
  sudo pacman -Sy --noconfirm 2>/dev/null || true
fi

read -r OFC AUR < <(count_updates)
TOTAL=$((OFC + AUR))

echo -e "  ${BOLD}Official:${RST}  ${YLW}${OFC}${RST}"
echo -e "  ${BOLD}AUR:${RST}       ${YLW}${AUR}${RST}"
echo -e "  ${BOLD}Total:${RST}     ${GRN}${TOTAL}${RST}\n"

if [[ "$TOTAL" -eq 0 ]]; then
  echo -e "${GRN}${BOLD}  ✓ System is up to date${RST}\n"
  read -n 1 -r -p "  Press any key to close..."
  exit 0
fi

echo -e "${YLW}Updates available.${RST}"
echo -e "  [1] Update everything (official + AUR)"
echo -e "  [2] Official only (pacman -Syu)"
echo -e "  [3] AUR only"
echo -e "  [q] Quit\n"
read -r -p "  Choice: " choice

case "$choice" in
  1)
    if command -v yay &>/dev/null; then
      yay -Syu
    elif command -v paru &>/dev/null; then
      paru -Syu
    else
      sudo pacman -Syu
    fi
    ;;
  2)
    sudo pacman -Syu
    ;;
  3)
    if command -v yay &>/dev/null; then
      yay -Sua
    elif command -v paru &>/dev/null; then
      paru -Sua
    else
      echo -e "${RED}No AUR helper found (yay/paru).${RST}"
      read -n 1 -r -p "  Press any key..."
      exit 1
    fi
    ;;
  q|Q)
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice.${RST}"
    read -n 1 -r -p "  Press any key..."
    exit 1
    ;;
esac

echo
echo -e "${GRN}${BOLD}  ✓ Finished${RST}\n"
# refresh waybar updater module if you use one
pkill -RTMIN+8 waybar 2>/dev/null || true
read -n 1 -r -p "  Press any key to close..."
