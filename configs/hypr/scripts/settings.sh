#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Hyprland (Lua) settings menu  –  requires: gum, sed, awk, hyprctl
#
#  Edits ONLY these files:
#    ~/.config/hypr/configs/general.lua      (gaps_in, gaps_out, border_size)
#    ~/.config/hypr/configs/decorations.lua  (rounding, active/inactive_opacity,
#                                             blur.size, blur.passes, shadow.range)
#    ~/.config/rofi/rofi-vars.rasi           (border-size, radius, radius-second)
#                                             – only if the file exists
#  Every file is backed up before its first change in a run.
# ─────────────────────────────────────────────────────────────

HYPR_DIR="${HYPR_DIR:-$HOME/.config/hypr}"
GENERAL="$HYPR_DIR/configs/general.lua"
DECOR="$HYPR_DIR/configs/decorations.lua"
ROFI_VARS="${ROFI_VARS:-$HOME/.config/rofi/rofi-vars.rasi}"
BACKUP_ROOT="$HYPR_DIR/backups"
KEEP_BACKUPS=10

BACKUP_DIR=""
HYPR_CHANGED=0
ROFI_CHANGED=0
REPLY_VAL=""

display() {
    cat << 'EOF'
            ╔═╗┬ ┬┌─┐┌┐┌┌─┐┌─┐  ╔═╗┌─┐┌┬┐┌┬┐┬┌┐┌┌─┐┌─┐            
            ║  ├─┤├─┤││││ ┬├┤   ╚═╗├┤  │  │ │││││ ┬└─┐            
────────────╚═╝┴ ┴┴ ┴┘└┘└─┘└─┘  ╚═╝└─┘ ┴  ┴ ┴┘└┘└─┘└─┘────────────
EOF
}

die()  { printf '\n[ !! ] %s\n' "$*" >&2; exit 1; }
warn() { printf '[ !! ] %s\n' "$*" >&2; }
info() { printf '[ ** ] %s\n' "$*"; }

# ── Lua helpers ──────────────────────────────────────────────
# Only lines of the form   <indent>key<spaces>=<spaces>value,   are touched.
# The key must match exactly ONE line in the file, otherwise nothing is written.

key_count() { grep -cE "^[[:space:]]*$2[[:space:]]*=" "$1"; }

lua_get() {
    sed -nE "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*([^,[:space:]]+).*/\1/p" "$1" | head -n1
}

backup_file() {
    local f=$1
    if [[ -z $BACKUP_DIR ]]; then
        BACKUP_DIR="$BACKUP_ROOT/settings-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR" || die "Cannot create $BACKUP_DIR"
    fi
    [[ -e $BACKUP_DIR/$(basename "$f") ]] || cp -p "$f" "$BACKUP_DIR/" || die "Backup of $f failed"
}

lua_set() { # file key value
    local f=$1 k=$2 v=$3 n
    [[ -w $f ]] || { warn "$f missing or not writable"; return 1; }
    n=$(key_count "$f" "$k")
    if [[ $n -ne 1 ]]; then
        warn "Expected exactly 1 '$k =' line in $(basename "$f"), found $n – not touching it."
        return 1
    fi
    backup_file "$f"
    sed -i -E "s/^([[:space:]]*$k[[:space:]]*=[[:space:]]*)[^,]*(,?.*)$/\1$v\2/" "$f"
    [[ "$(lua_get "$f" "$k")" == "$v" ]] || { warn "Verification failed for $k"; return 1; }
    HYPR_CHANGED=1
    info "$(basename "$f"): $k = $v"
}

rofi_set() { # key value
    local k=$1 v=$2
    [[ -f $ROFI_VARS ]] || { warn "Rofi vars not found ($ROFI_VARS) – skipping Rofi sync."; return 0; }
    if ! grep -qE "^[[:space:]]*$k:[[:space:]]*[^;]*;" "$ROFI_VARS"; then
        warn "No '$k:' entry in rofi-vars.rasi – skipping."
        return 0
    fi
    backup_file "$ROFI_VARS"
    sed -i -E "s/^([[:space:]]*)$k:[[:space:]]*[^;]*;/\1$k: $v;/" "$ROFI_VARS"
    ROFI_CHANGED=1
    info "rofi-vars.rasi: $k: $v"
}

# ── Input ────────────────────────────────────────────────────
# prompt_number LABEL CURRENT MIN MAX int|float  → sets REPLY_VAL, returns 1 if skipped
prompt_number() {
    local label=$1 cur=$2 min=$3 max=$4 kind=$5 val re
    [[ $kind == int ]] && re='^[0-9]+$' || re='^[0-9]+(\.[0-9]+)?$'
    while true; do
        val=$(gum input --header "$label  (current: ${cur:-?}, allowed: $min–$max, empty = skip)" \
                        --placeholder "Type a number..." --value "") || return 1
        [[ -z $val ]] && return 1
        if [[ $val =~ $re ]] && awk -v v="$val" -v lo="$min" -v hi="$max" \
              'BEGIN{exit !(v+0>=lo && v+0<=hi)}'; then
            [[ $kind == int ]] && val=$((10#$val))
            REPLY_VAL=$val
            return 0
        fi
        gum style --foreground 196 "Invalid input. Enter a number between $min and $max."
    done
}

# ── Reload / rollback ───────────────────────────────────────
restore_backup() {
    [[ -n $BACKUP_DIR ]] || return 0
    [[ -f $BACKUP_DIR/general.lua ]]     && cp -p "$BACKUP_DIR/general.lua"     "$GENERAL"
    [[ -f $BACKUP_DIR/decorations.lua ]] && cp -p "$BACKUP_DIR/decorations.lua" "$DECOR"
    [[ -f $BACKUP_DIR/rofi-vars.rasi ]]  && cp -p "$BACKUP_DIR/rofi-vars.rasi"  "$ROFI_VARS"
    info "Restored files from $BACKUP_DIR"
    hyprctl reload >/dev/null 2>&1
}

prune_backups() {
    [[ -d $BACKUP_ROOT ]] || return 0
    ls -1dt "$BACKUP_ROOT"/settings-* 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm -rf
}

reload_hypr() {
    [[ $HYPR_CHANGED -eq 1 ]] || return 0
    printf '\n[ ** ] Reloading Hyprland configuration...\n' && sleep 1
    hyprctl reload
    sleep 0.5
    local errs
    errs=$(hyprctl configerrors 2>&1)
    if [[ -n ${errs//[[:space:]]/} ]]; then
        gum style --foreground 214 "Hyprland reported config messages:"
        printf '%s\n' "$errs"
        if gum confirm "Restore the backup taken before these changes?"; then
            restore_backup
        fi
    fi
}

# ── Main ─────────────────────────────────────────────────────
main() {
    command -v gum >/dev/null 2>&1      || die "gum is not installed (sudo pacman -S gum)"
    command -v hyprctl >/dev/null 2>&1  || die "hyprctl not found"
    [[ -f $GENERAL && -f $DECOR ]]      || die "Missing $GENERAL or $DECOR"

    # Interactive selector: Space toggles, Ctrl+A selects all settings,
    # arrows move, Enter confirms, Esc exits. Does not depend on Gum's key handling.
    local -a options=("border size" "roundness" "inner gap" "outer gap" "blur" "opacity" "shadow" "cancel")
    local -A selected=()
    local cursor=0 key seq i choice
    picks=()

    while true; do
        clear
        display
        printf '\n  => Choose which settings you want to change\n'
        printf '  ↑/↓ move  Space toggle  Ctrl+A select all  Enter confirm  Esc quit\n\n'
        for i in "${!options[@]}"; do
            if [[ ${selected[${options[$i]}]:-0} -eq 1 ]]; then
                printf '  [x] '
            else
                printf '  [ ] '
            fi
            if [[ $i -eq $cursor ]]; then
                printf '\033[1;38;5;183m> %s\033[0m\n' "${options[$i]}"
            else
                printf '    %s\n' "${options[$i]}"
            fi
        done

        IFS= read -rsn1 key || exit 0
        case "$key" in
            $'\x1b')
                # Distinguish an arrow key from a standalone Esc.
                if IFS= read -rsn1 -t 0.05 seq; then
                    if [[ $seq == '[' ]]; then
                        IFS= read -rsn1 -t 0.05 seq || seq=''
                        case "$seq" in
                            A) (( cursor > 0 )) && ((cursor--)) ;;
                            B) (( cursor < ${#options[@]} - 1 )) && ((cursor++)) ;;
                        esac
                    fi
                else
                    exit 0
                fi
                ;;
            $'\x01')
                # Select all real settings, deliberately excluding Cancel.
                for i in "${options[@]:0:7}"; do selected["$i"]=1; done
                selected["cancel"]=0
                ;;
            ' ')
                if [[ ${selected[${options[$cursor]}]:-0} -eq 1 ]]; then
                    selected["${options[$cursor]}"]=0
                else
                    selected["${options[$cursor]}"]=1
                fi
                ;;
            '')
                # Enter: cancel only when Cancel is selected by itself.
                picks=()
                for i in "${options[@]:0:7}"; do
                    [[ ${selected[$i]:-0} -eq 1 ]] && picks+=("$i")
                done
                if [[ ${#picks[@]} -gt 0 ]]; then
                    break
                elif [[ ${selected[cancel]:-0} -eq 1 ]]; then
                    exit 0
                fi
                ;;
            *) ;;
        esac
    done

    local p
    for p in "${picks[@]}"; do
        clear
        case "$p" in
        "border size")
            printf '\n[ <> ]\nSetting border size...\n\n'
            if prompt_number "Border width" "$(lua_get "$GENERAL" border_size)" 0 20 int; then
                lua_set "$GENERAL" border_size "$REPLY_VAL" && rofi_set border-size "${REPLY_VAL}px"
            fi ;;
        "roundness")
            printf '\n[ <> ]\nSetting border roundness...\n\n'
            if prompt_number "Roundness" "$(lua_get "$DECOR" rounding)" 0 50 int; then
                if lua_set "$DECOR" rounding "$REPLY_VAL"; then
                    rofi_set radius "${REPLY_VAL}px"
                    rofi_set radius-second "$((REPLY_VAL / 2))px"
                fi
            fi ;;
        "inner gap")
            printf '\n[ <> ]\nSetting inner gap...\n\n'
            prompt_number "Inner gap (gaps_in)" "$(lua_get "$GENERAL" gaps_in)" 0 100 int \
                && lua_set "$GENERAL" gaps_in "$REPLY_VAL" ;;
        "outer gap")
            printf '\n[ <> ]\nSetting outer gap...\n\n'
            prompt_number "Outer gap (gaps_out)" "$(lua_get "$GENERAL" gaps_out)" 0 200 int \
                && lua_set "$GENERAL" gaps_out "$REPLY_VAL" ;;
        "blur")
            printf '\n[ <> ]\nSetting blur...\n\n'
            local bs bp
            if prompt_number "Blur size" "$(lua_get "$DECOR" size)" 1 20 int; then
                bs=$REPLY_VAL
                if prompt_number "Blur passes" "$(lua_get "$DECOR" passes)" 1 8 int; then
                    bp=$REPLY_VAL
                    lua_set "$DECOR" size "$bs"
                    lua_set "$DECOR" passes "$bp"
                fi
            fi ;;
        "opacity")
            printf '\n[ <> ]\nSetting opacity...\n\n'
            prompt_number "Active opacity (ex: 0.9)" "$(lua_get "$DECOR" active_opacity)" 0 1 float \
                && lua_set "$DECOR" active_opacity "$REPLY_VAL"
            prompt_number "Inactive opacity (ex: 0.9)" "$(lua_get "$DECOR" inactive_opacity)" 0 1 float \
                && lua_set "$DECOR" inactive_opacity "$REPLY_VAL" ;;
        "shadow")
            printf '\n[ <> ]\nSetting shadow range ( 0 means no shadow )...\n\n'
            prompt_number "Shadow range" "$(lua_get "$DECOR" range)" 0 100 int \
                && lua_set "$DECOR" range "$REPLY_VAL" ;;
        *)  echo "Invalid choice: $p" ;;
        esac
    done

    reload_hypr
    prune_backups
    [[ -n $BACKUP_DIR ]] && info "Backup: $BACKUP_DIR"
    [[ $ROFI_CHANGED -eq 1 ]] && info "Rofi picks up changes next time it launches."
    printf '\nPress any key to close...'; read -rsn1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi

