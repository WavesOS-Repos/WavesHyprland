#!/usr/bin/env bash
# common.sh — shared helpers (quiet by default)
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$COMMON_DIR/.." && pwd)"
USER_HOME="${SUDO_USER:+$(getent passwd "$SUDO_USER" | cut -d: -f6)}"
USER_HOME="${USER_HOME:-$HOME}"
CONFIG_DIR="${USER_HOME}/.config"
LOCAL_SHARE="${USER_HOME}/.local/share"
BACKUP_ROOT="${CONFIG_DIR}/WavesHyprland-backup-$(date +%Y%m%d-%H%M%S)"

# Quiet mode: only errors (and final messages from install.sh)
WAVES_QUIET="${WAVES_QUIET:-1}"

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_CYAN='\033[0;36m'
  C_GRN='\033[0;32m'
  C_YLW='\033[1;33m'
  C_RED='\033[0;31m'
  C_BOLD='\033[1m'
else
  C_RESET= C_CYAN= C_GRN= C_YLW= C_RED= C_BOLD=
fi

log()  { [[ "$WAVES_QUIET" == "1" ]] && return 0; printf "%b[>]%b %s\n" "$C_CYAN" "$C_RESET" "$*"; }
ok()   { [[ "$WAVES_QUIET" == "1" ]] && return 0; printf "%b[✓]%b %s\n" "$C_GRN" "$C_RESET" "$*"; }
warn() { printf "%b[!]%b %s\n" "$C_YLW" "$C_RESET" "$*" >&2; }
err()  { printf "%b[x]%b %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

# Run command silently; on failure print exact error
run_quiet() {
  local desc="$1"
  shift
  local errf
  errf="$(mktemp)"
  if "$@" >"$errf" 2>&1; then
    rm -f "$errf"
    return 0
  else
    local ec=$?
    err "FAILED: $desc (exit $ec)"
    if [[ -s "$errf" ]]; then
      sed 's/^/    /' "$errf" >&2
    fi
    rm -f "$errf"
    return "$ec"
  fi
}

require_arch() {
  [[ -f /etc/arch-release ]] || die "This installer targets Arch Linux (pacman)."
}

show_logo() {
  local logo="$ROOT/assets/logo.txt"
  if [[ -f "$logo" ]]; then
    cat "$logo"
    return
  fi
  printf "%b" "${C_CYAN}${C_BOLD}"
  cat << 'LOGO'
 __        __                   _   _                 _                 _
 \ \      / /_ ___   _____  ___| | | |_   _ _ __ _ __| | __ _ _ __   __| |
  \ \ /\ / / _` \ \ / / _ \/ __| |_| | | | | '__| '__| |/ _` | '_ \ / _` |
   \ V  V / (_| |\ V /  __/\__ \  _  | |_| | |  | |  | | (_| | | | | (_| |
    \_/\_/ \__,_| \_/ \___||___/_| |_|\__, |_|  |_|  |_|\__,_|_| |_|\__,_|
                                      |___/
LOGO
  printf "%b\n" "$C_RESET"
}
