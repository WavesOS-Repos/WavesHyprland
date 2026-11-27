#!/usr/bin/env bash
# WavesOS / WavesHyprland — safe rice update + reset
# Usage:
#   rice-update.sh safe
#   rice-update.sh reset

set -uo pipefail

MODE="${1:-safe}"

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
BLU='\033[0;34m'; CYN='\033[0;36m'; BOLD='\033[1m'; RST='\033[0m'

SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/waveshyprland"
REPO_DIR="${SHARE}/repo"
REPO_URL="${WAVES_REPO_URL:-https://github.com/WavesOS-Repos/WavesHyprland.git}"
MANIFEST="${SHARE}/stock-manifest"
VERSION_FILE="${SHARE}/version"
LOG="${SHARE}/last-update.log"
BACKUP_ROOT="${SHARE}/backups/$(date +%Y%m%d-%H%M%S)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

UPDATED=()
SKIPPED=()
NEW_FILES=()
PKGS=()
KEYBINDS_ADDED=()
KEYBINDS_SKIPPED=()
CLEANED=()
OBSOLETE_REMOVED=()
OBSOLETE_SKIPPED=()

log()  { printf '%s\n' "$*" | tee -a "$LOG" >/dev/null; printf '%b\n' "$*"; }
info() { printf '%b%s%b\n' "$CYN" "$*" "$RST" | tee -a "$LOG" >/dev/null; }
ok()   { printf '%b%s%b\n' "$GRN" "$*" "$RST" | tee -a "$LOG" >/dev/null; }
warn() { printf '%b%s%b\n' "$YLW" "$*" "$RST" | tee -a "$LOG" >/dev/null; }
err()  { printf '%b%s%b\n' "$RED" "$*" "$RST" | tee -a "$LOG" >/dev/null; }

mkdir -p "$SHARE" "$SHARE/backups"
: >"$LOG"

file_hash() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

manifest_get() {
  local key="$1"
  [[ -f "$MANIFEST" ]] || return 1
  awk -F '\t' -v k="$key" '$1==k {print $2; exit}' "$MANIFEST"
}

manifest_set() {
  local key="$1" hash="$2"
  mkdir -p "$(dirname "$MANIFEST")"
  local tmp
  tmp="$(mktemp)"
  if [[ -f "$MANIFEST" ]]; then
    awk -F '\t' -v k="$key" '$1!=k {print}' "$MANIFEST" >"$tmp"
  else
    : >"$tmp"
  fi
  printf '%s\t%s\n' "$key" "$hash" >>"$tmp"
  mv "$tmp" "$MANIFEST"
}

is_protected() {
  local rel="$1"
  case "$rel" in
    hypr/configs/keybinds-user.lua|\
    hypr/configs/monitors.lua|\
    hypr/configs/plugins.lua|\
    hypr/matugen-colors.lua|\
    waybar/config|waybar/style.css|\
    wallfliper/state.json|\
    hypr/plugins/*)
      return 0
      ;;
  esac
  return 1
}

backup_file() {
  local src="$1"
  [[ -e "$src" ]] || return 0
  local rel="${src#"$CONFIG"/}"
  mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
  cp -a "$src" "$BACKUP_ROOT/$rel" 2>/dev/null || true
}

ensure_repo() {
  info "Syncing WavesHyprland repository…"
  if [[ -d "$REPO_DIR/.git" ]]; then
    git -C "$REPO_DIR" fetch --depth 1 origin 2>>"$LOG" || { err "git fetch failed"; return 1; }
    git -C "$REPO_DIR" reset --hard origin/main 2>>"$LOG" \
      || git -C "$REPO_DIR" reset --hard origin/master 2>>"$LOG" \
      || { err "git reset failed"; return 1; }
  else
    rm -rf "$REPO_DIR"
    git clone --depth 1 "$REPO_URL" "$REPO_DIR" 2>>"$LOG" || { err "git clone failed"; return 1; }
  fi
  ok "Repo ready: $REPO_DIR"
}

install_missing_packages() {
  local pac="$REPO_DIR/packages/pacman.txt"
  local aur="$REPO_DIR/packages/aur.txt"
  local pkg

  if [[ -f "$pac" ]]; then
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
      [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
      pacman -Q "$pkg" &>/dev/null && continue
      info "Installing package: $pkg"
      if sudo -n pacman -S --needed --noconfirm "$pkg" >>"$LOG" 2>&1; then
        PKGS+=("$pkg")
      else
        warn "Failed package: $pkg"
      fi
    done <"$pac"
  fi

  if [[ -f "$aur" ]] && command -v yay &>/dev/null; then
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
      [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
      pacman -Q "$pkg" &>/dev/null && continue
      info "Installing AUR: $pkg"
      if yay -S --needed --noconfirm "$pkg" >>"$LOG" 2>&1; then
        PKGS+=("$pkg")
      else
        warn "Failed AUR: $pkg"
      fi
    done <"$aur"
  fi
}

# Deploy one file from repo configs/ → ~/.config/
deploy_stock_file() {
  local src="$1"
  local rel="${src#"$REPO_DIR/configs/"}"
  local dst="$CONFIG/$rel"

  is_protected "$rel" && { SKIPPED+=("$rel (protected)"); return 0; }

  if [[ ! -e "$dst" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    NEW_FILES+=("$rel")
    manifest_set "$rel" "$(file_hash "$dst")"
    return 0
  fi

  local old_stock
  old_stock="$(manifest_get "$rel" || true)"
  local cur
  cur="$(file_hash "$dst")"

  # User-modified since last stock apply
  if [[ -n "$old_stock" && "$cur" != "$old_stock" ]]; then
    SKIPPED+=("$rel (user modified)")
    return 0
  fi

  # Same as new stock — nothing to do
  local new_hash
  new_hash="$(file_hash "$src")"
  if [[ "$cur" == "$new_hash" ]]; then
    manifest_set "$rel" "$new_hash"
    return 0
  fi

  # Unmodified stock or first tracked → update
  backup_file "$dst"
  cp -a "$src" "$dst"
  UPDATED+=("$rel")
  manifest_set "$rel" "$(file_hash "$dst")"
}

deploy_tree_safe() {
  local sub="$1"
  local root="$REPO_DIR/configs/$sub"
  [[ -d "$root" ]] || return 0
  while IFS= read -r -d '' f; do
    deploy_stock_file "$f"
  done < <(find "$root" -type f \
    ! -name 'PLACEHOLDER.txt' ! -name '.gitkeep' \
    ! -path '*/qylock/themes/*' ! -path '*/qylock/Assets/*' \
    -print0 2>/dev/null)
}

migrate_keybinds() {
  local stock="$CONFIG/hypr/configs/keybinds-stock.lua"
  local user="$CONFIG/hypr/configs/keybinds-user.lua"
  local legacy="$CONFIG/hypr/configs/keybinds.lua"
  local rstock="$REPO_DIR/configs/hypr/configs/keybinds-stock.lua"
  local ruser="$REPO_DIR/configs/hypr/configs/keybinds-user.lua"

  mkdir -p "$CONFIG/hypr/configs"

  if [[ -f "$legacy" && ! -f "$user" ]]; then
    backup_file "$legacy"
    cp -a "$legacy" "$user"
    ok "Migrated keybinds.lua → keybinds-user.lua"
  fi

  if [[ -f "$rstock" ]]; then
    deploy_stock_file "$rstock"
  fi
  if [[ -f "$ruser" && ! -f "$user" ]]; then
    cp -a "$ruser" "$user"
    NEW_FILES+=("hypr/configs/keybinds-user.lua")
  fi
  [[ -f "$user" ]] || printf '%s\n' "-- User keybinds (never overwritten by rice update)" >"$user"
}

chord_in_file() {
  local chord="$1" file="$2"
  [[ -f "$file" ]] || return 1
  # Normalize: strip spaces for search
  local c="${chord// /}"
  grep -qiE "${c//+/\\+}" "$file" 2>/dev/null
}

process_new_keybinds() {
  local tsv="$REPO_DIR/configs/hypr/configs/stock-keybinds.tsv"
  local user="$CONFIG/hypr/configs/keybinds-user.lua"
  local stock="$CONFIG/hypr/configs/keybinds-stock.lua"
  [[ -f "$tsv" ]] || return 0

  local chord label note line newbind
  while IFS=$'\t' read -r chord label note || [[ -n "$chord" ]]; do
    [[ -z "$chord" || "$chord" =~ ^# ]] && continue
    label="${label:-new feature}"
    note="${note:-}"

    if chord_in_file "$chord" "$stock" || chord_in_file "$chord" "$user"; then
      # If already present as this feature, skip quietly
      if chord_in_file "$chord" "$user" || chord_in_file "$chord" "$stock"; then
        # Conflict if user has same chord for something else — still prompt only when
        # stock-keybinds says it's new AND chord exists in user file
        if chord_in_file "$chord" "$user"; then
          echo
          warn "Keybind conflict for new feature: $label"
          echo -e "  Default: ${BOLD}${chord}${RST}  (${note})"
          echo "  Already used in your keybinds-user.lua"
          echo "  Enter a new chord (e.g. SUPER+ALT+P), or [s] to skip:"
          read -r -p "  > " newbind || newbind=s
          if [[ -z "$newbind" || "$newbind" == s || "$newbind" == S ]]; then
            KEYBINDS_SKIPPED+=("$label ($chord)")
            continue
          fi
          {
            echo ""
            echo "-- added by rice-update: $label"
            echo "-- TODO: wire dispatcher for: $note"
            echo "-- chord: $newbind"
          } >>"$user"
          KEYBINDS_ADDED+=("$newbind → $label (manual wire if needed)")
          continue
        fi
      fi
      continue
    fi
  done <"$tsv"
}

cleanup_after() {
  info "Cleanup…"
  # temps
  rm -f /tmp/waveshyprland-* /tmp/waves-*-err* 2>/dev/null || true
  CLEANED+=("temp files")

  # broken symlinks in managed dirs
  local d
  for d in "$CONFIG/hypr" "$CONFIG/waybar" "$SHARE"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' l; do
      rm -f "$l" && CLEANED+=("broken link: $l")
    done < <(find "$d" -xtype l -print0 2>/dev/null)
  done

  # obsolete stock paths
  local obs="$REPO_DIR/packages/obsolete-stock.txt"
  if [[ -f "$obs" ]]; then
    local rel dst cur old
    while IFS= read -r rel || [[ -n "$rel" ]]; do
      [[ -z "$rel" || "$rel" =~ ^# ]] && continue
      dst="$CONFIG/$rel"
      [[ -e "$dst" ]] || continue
      old="$(manifest_get "$rel" || true)"
      cur="$(file_hash "$dst")"
      if [[ -n "$old" && "$cur" == "$old" ]]; then
        backup_file "$dst"
        rm -f "$dst"
        OBSOLETE_REMOVED+=("$rel")
      else
        OBSOLETE_SKIPPED+=("$rel")
      fi
    done <"$obs"
  fi

  # prune old backups (keep 5)
  local bcount
  bcount="$(find "$SHARE/backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  if (( bcount > 5 )); then
    find "$SHARE/backups" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
      | sort -n | head -n $((bcount - 5)) | awk '{print $2}' \
      | while read -r oldb; do rm -rf "$oldb"; CLEANED+=("old backup pruned"); done
  fi

  git -C "$REPO_DIR" gc --auto 2>/dev/null || true
}

write_version() {
  local ver
  ver="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"
  printf '%s\n' "$ver" >"$VERSION_FILE"
}

summary() {
  local ver_old ver_new
  ver_old="$(cat "$VERSION_FILE" 2>/dev/null || echo none)"
  ver_new="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"
  # version file already written — show previous from log header if needed
  echo
  echo -e "${BOLD}────────────────────────────────────────${RST}"
  echo -e "${BOLD}  WavesHyprland update summary${RST}"
  echo -e "${BOLD}────────────────────────────────────────${RST}"
  echo -e "  Mode:     ${MODE}"
  echo -e "  Version:  ${ver_new}"
  echo -e "  Backup:   ${BACKUP_ROOT}"
  echo -e "  Log:      ${LOG}"
  echo
  echo -e "  Packages installed: ${#PKGS[@]}"
  ((${#PKGS[@]})) && printf '    - %s\n' "${PKGS[@]}"
  echo -e "  Files updated:      ${#UPDATED[@]}"
  ((${#UPDATED[@]})) && printf '    - %s\n' "${UPDATED[@]}"
  echo -e "  New files:          ${#NEW_FILES[@]}"
  ((${#NEW_FILES[@]})) && printf '    - %s\n' "${NEW_FILES[@]}"
  echo -e "  Skipped (yours):    ${#SKIPPED[@]}"
  ((${#SKIPPED[@]})) && printf '    - %s\n' "${SKIPPED[@]}"
  echo -e "  Keybinds added:     ${#KEYBINDS_ADDED[@]}"
  ((${#KEYBINDS_ADDED[@]})) && printf '    - %s\n' "${KEYBINDS_ADDED[@]}"
  echo -e "  Keybinds skipped:   ${#KEYBINDS_SKIPPED[@]}"
  ((${#KEYBINDS_SKIPPED[@]})) && printf '    - %s\n' "${KEYBINDS_SKIPPED[@]}"
  echo -e "  Obsolete removed:   ${#OBSOLETE_REMOVED[@]}"
  echo -e "  Cleanup notes:      ${#CLEANED[@]}"
  echo -e "${BOLD}────────────────────────────────────────${RST}"
  echo -e "${BLU}Plugins: enable state was not changed.${RST}"
}

soft_reload() {
  if command -v hyprctl &>/dev/null; then
    hyprctl reload >/dev/null 2>&1 && ok "hyprctl reload" || warn "hyprctl reload failed"
  fi
  pkill -RTMIN+8 waybar 2>/dev/null || true
}

mode_safe() {
  ensure_repo || return 1
  mkdir -p "$BACKUP_ROOT"
  install_missing_packages
  migrate_keybinds

  # Prefer scripts + hypr stock configs; full configs/ tree with protection
  if [[ -d "$REPO_DIR/configs/hypr/scripts" ]]; then
    deploy_tree_safe "hypr/scripts"
  fi
  if [[ -d "$REPO_DIR/configs/hypr/configs" ]]; then
    deploy_tree_safe "hypr/configs"
  fi
  # other components (missing + unmodified only)
  for sub in waybar rofi eww matugen kitty wlogout swaync; do
    deploy_tree_safe "$sub"
  done

  process_new_keybinds
  soft_reload
  cleanup_after
  write_version
  summary
}

mode_reset() {
  echo -e "${RED}${BOLD}"
  echo "  This will REINSTALL WavesHyprland stock configs."
  echo "  Your custom keybinds/layouts may be overwritten."
  echo -e "${RST}"
  echo "  Type RESET (all caps) to continue, or anything else to abort:"
  read -r -p "  > " conf
  [[ "$conf" == "RESET" ]] || { warn "Reset aborted."; return 1; }

  ensure_repo || return 1
  mkdir -p "$BACKUP_ROOT"
  # backup managed trees
  for d in hypr waybar rofi eww matugen kitty wlogout swaync wallfliper; do
    [[ -d "$CONFIG/$d" ]] && cp -a "$CONFIG/$d" "$BACKUP_ROOT/$d" 2>/dev/null || true
  done

  install_missing_packages

  # full copy of configs (still skip enormous qylock media if present under configs)
  if [[ -d "$REPO_DIR/configs" ]]; then
    while IFS= read -r -d '' f; do
      local rel="${f#"$REPO_DIR/configs/"}"
      case "$rel" in
        qylock/themes/*|qylock/Assets/*) continue ;;
      esac
      local dst="$CONFIG/$rel"
      mkdir -p "$(dirname "$dst")"
      cp -a "$f" "$dst"
      manifest_set "$rel" "$(file_hash "$dst")"
      UPDATED+=("$rel")
    done < <(find "$REPO_DIR/configs" -type f \
      ! -name 'PLACEHOLDER.txt' -print0 2>/dev/null)
  fi

  migrate_keybinds
  soft_reload
  cleanup_after
  write_version
  summary
  ok "Reset complete. Backup: $BACKUP_ROOT"
}

case "$MODE" in
  safe)  mode_safe ;;
  reset) mode_reset ;;
  *) err "Usage: $0 safe|reset"; exit 1 ;;
esac
