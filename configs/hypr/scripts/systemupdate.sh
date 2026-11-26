#!/usr/bin/env bash
# sysupdate.sh — Arch Linux system updater for Kitty / terminal use

set -uo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
RST='\033[0m'
BOLD='\033[1m'

FAILED=()
SUDO_KEEPALIVE_PID=""

banner() {
    clear 2>/dev/null || true
    echo -e "${CYN}${BOLD}"
    echo "  ╔════════════════════════════════════════════╗"
    echo "  ║              System Updater                ║"
    echo "  ╚════════════════════════════════════════════╝"
    echo -e "${RST}"
}

finish() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

trap finish EXIT

pause_and_exit() {
    echo
    read -r -n 1 -s -p "  Press any key to close..." || true
    echo
}

has_aur_helper() {
    command -v yay >/dev/null 2>&1 || command -v paru >/dev/null 2>&1
}

aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        printf '%s\n' yay
    elif command -v paru >/dev/null 2>&1; then
        printf '%s\n' paru
    else
        return 1
    fi
}

# Ask for sudo credentials once. Keep the timestamp alive while updates run.
prepare_sudo() {
    echo -e "${BLU}Administrator authentication is needed for system package updates.${RST}"
    echo -e "${YLW}Enter your password once; the updater will reuse the sudo session.${RST}"
    if ! sudo -v; then
        echo -e "${RED}Authentication failed. Nothing was updated.${RST}"
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
        echo -e "${RED}✗ ${label} failed (exit ${status}). Continuing with the remaining updates.${RST}"
        FAILED+=("$label")
    fi
}

update_official() {
    sudo -n pacman -Syu --noconfirm
}

update_aur() {
    local helper
    helper="$(aur_helper)" || {
        echo -e "${YLW}No AUR helper found (yay/paru); skipping AUR updates.${RST}"
        return 1
    }
    "$helper" -Sua --noconfirm
}

update_everything_arch() {
    local helper
    helper="$(aur_helper)" || {
        # Pacman can still update official packages without an AUR helper.
        sudo -n pacman -Syu --noconfirm
        return
    }
    # yay/paru -Syu updates official repository packages and installed AUR packages.
    "$helper" -Syu --noconfirm
}

update_flatpak() {
    if ! command -v flatpak >/dev/null 2>&1; then
        echo -e "${YLW}Flatpak is not installed; skipping.${RST}"
        return 0
    fi

    # User installation runs as the logged-in user.
    flatpak update --user --assumeyes

    # System installation uses the already-authenticated sudo session.
    sudo -n flatpak update --system --assumeyes
}

update_hyprpm() {
    if ! command -v hyprpm >/dev/null 2>&1; then
        echo -e "${YLW}hyprpm is not installed; skipping.${RST}"
        return 0
    fi

    # Run as the logged-in user. hyprpm may invoke sudo internally when
    # installing/updating Hyprland headers; the cached sudo session is reused.
    hyprpm update
}

count_updates() {
    local official=0 aur=0 flatpak_user=0 flatpak_system=0

    if command -v checkupdates >/dev/null 2>&1; then
        official="$(checkupdates 2>/dev/null | wc -l | tr -d ' ')" || official=0
    fi

    if command -v yay >/dev/null 2>&1; then
        aur="$(yay -Qua 2>/dev/null | wc -l | tr -d ' ')" || aur=0
    elif command -v paru >/dev/null 2>&1; then
        aur="$(paru -Qua 2>/dev/null | wc -l | tr -d ' ')" || aur=0
    fi

    if command -v flatpak >/dev/null 2>&1; then
        flatpak_user="$(flatpak remote-ls --updates --user 2>/dev/null | wc -l | tr -d ' ')" || flatpak_user=0
        flatpak_system="$(flatpak remote-ls --updates --system 2>/dev/null | wc -l | tr -d ' ')" || flatpak_system=0
    fi

    printf '%s %s %s %s\n' "$official" "$aur" "$flatpak_user" "$flatpak_system"
}

banner

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Do not run this updater as root. Run it as your normal user.${RST}"
    pause_and_exit
    exit 1
fi

echo -e "${BLU}Checking available updates...${RST}\n"
read -r OFC AUR FLATPAK_USER FLATPAK_SYSTEM < <(count_updates)

echo -e "  ${BOLD}Official packages:${RST} ${YLW}${OFC}${RST}"
echo -e "  ${BOLD}AUR packages:${RST}      ${YLW}${AUR}${RST}"
echo -e "  ${BOLD}Flatpak (user):${RST}    ${YLW}${FLATPAK_USER}${RST}"
echo -e "  ${BOLD}Flatpak (system):${RST}  ${YLW}${FLATPAK_SYSTEM}${RST}"
echo -e "  ${BOLD}Hyprpm:${RST}            checked when update runs"
echo
echo -e "${YLW}Choose what to update:${RST}"
echo "  [1] Update everything (Pacman + AUR + Flatpak + Hyprpm)"
echo "  [2] Official packages only (Pacman)"
echo "  [3] AUR packages only"
echo "  [4] Flatpak only (user + system installations)"
echo "  [5] Hyprpm only"
echo "  [q] Quit"
echo

read -r -p "  Choice: " choice

case "$choice" in
    1|2|3|4|5) ;;
    q|Q) exit 0 ;;
    *)
        echo -e "${RED}Invalid choice.${RST}"
        exit 1
        ;;
esac

# All choices except user-only Flatpak may need administrator access.
if [[ "$choice" != "4" ]] || { command -v flatpak >/dev/null 2>&1; }; then
    if ! prepare_sudo; then
        exit 1
    fi
fi

case "$choice" in
    1)
        run_step "Pacman + AUR" update_everything_arch
        run_step "Flatpak (user + system)" update_flatpak
        # Run after package updates so Hyprland headers match the updated version.
        run_step "Hyprpm plugins" update_hyprpm
        ;;
    2)
        run_step "Official packages (Pacman)" update_official
        ;;
    3)
        run_step "AUR packages" update_aur
        ;;
    4)
        run_step "Flatpak (user + system)" update_flatpak
        ;;
    5)
        run_step "Hyprpm plugins" update_hyprpm
        ;;
esac

echo
echo -e "${BOLD}────────────────────────────────────────────${RST}"
if ((${#FAILED[@]} == 0)); then
    echo -e "${GRN}${BOLD}✓ All selected update tasks finished successfully.${RST}"
else
    echo -e "${YLW}${BOLD}Finished with ${#FAILED[@]} failed task(s):${RST}"
    printf '  - %s\n' "${FAILED[@]}"
fi
echo
echo -e "${BLU}Waybar updater module refreshed.${RST}"

