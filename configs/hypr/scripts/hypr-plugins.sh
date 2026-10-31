#!/usr/bin/env bash
# WavesOS Hyprland Plugin Manager
# Website catalogue snapshot: https://hypr.land/plugins/
# Keys: Up/Down move, Space toggle, Enter apply, Esc cancel.

set -uo pipefail

HYPR_DIR="${HYPR_DIR:-$HOME/.config/hypr}"
PLUGIN_DIR="${PLUGIN_DIR:-$HYPR_DIR/plugins}"
LOG_DIR="${LOG_DIR:-$HYPR_DIR/logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/plugin-manager-$(date +%Y%m%d-%H%M%S).log}"
SHOW_BANNER="${SHOW_BANNER:-1}"

# id|display name|repository URL|hyprpm plugin id|type
# GitHub /tree/... URLs from the website are normalized to their repository root.
# "external" entries are listed but are not shared-object plugins managed by hyprpm.
read -r -d '' BUILTIN_CATALOG <<'CATALOG' || true
hy3|hy3|https://github.com/outfoxxed/hy3|hy3|hyprpm
hyprwinwrap|Hyprwinwrap|https://github.com/gen3vra/hyprwinwrap|hyprwinwrap|hyprpm
hyprgrass|hyprgrass|https://github.com/horriblename/hyprgrass|hyprgrass|hyprpm
split-monitor-workspaces|split-monitor-workspaces|https://github.com/Duckonaut/split-monitor-workspaces|split-monitor-workspaces|hyprpm
hyprland-easymotion|hyprland-easymotion|https://github.com/zakk4223/hyprland-easymotion|hyprEasymotion|hyprpm
hypr-dynamic-cursors|hypr-dynamic-cursors|https://github.com/VirtCode/hypr-dynamic-cursors|dynamic-cursors|hyprpm
hypr-edgehover|hypr-edgehover|https://github.com/gfhdhytghd/hypr-edgehover|hypr-edgehover|hyprpm
hymission|hymission|https://github.com/gfhdhytghd/hymission|hymission|hyprpm
hyprcapture|hyprcapture|https://github.com/gfhdhytghd/HyprCapture|hyprcapture|hyprpm
hypr-kinetic-scroll|hypr-kinetic-scroll|https://github.com/savonovv/hypr-kinetic-scroll|hypr-kinetic-scroll|hyprpm
gloview|gloview|https://github.com/fedsfarm/gloview|gloview|hyprpm
confined-floats|confined-floats|https://github.com/mennemann/hyprland-confined-floats|confined-floats|hyprpm
macos-zoom|macos-zoom|https://github.com/aastrand/hyprland-macos-zoom|macos-zoom|hyprpm
hyprNStack|hyprNStack|https://github.com/zakk4223/hyprNStack|hyprNStack|hyprpm
hyprland-virtual-desktops|hyprland-virtual-desktops|https://github.com/levnikmyskin/hyprland-virtual-desktops|hyprland-virtual-desktops|hyprpm
hyprRiver|hyprRiver|https://github.com/zakk4223/hyprRiver|hyprRiver|hyprpm
borders-plus-plus|Borders++|https://github.com/hyprwm/hyprland-plugins|borders-plus-plus|hyprpm
imgborders|Image borders|https://codeberg.org/zacoons/imgborders|imgborders|hyprpm
hyprbars|Hyprbars|https://github.com/hyprwm/hyprland-plugins|hyprbars|hyprpm
hyprtrails|Hyprtrails|https://github.com/hyprwm/hyprland-plugins|hyprtrails|hyprpm
hyprfocus|Hyprfocus|https://github.com/hyprwm/hyprland-plugins|hyprfocus|hyprpm
hypr-darkwindow|hypr-darkwindow|https://github.com/micha4w/Hypr-DarkWindow|Hypr-DarkWindow|hyprpm
hyprexpo-sandwichfarm|sandwichfarm/hyprexpo|https://github.com/sandwichfarm/hyprexpo|hyprexpo|hyprpm
hyprexpo-colonelpanic8|colonelpanic8/hyprexpo|https://github.com/colonelpanic8/hyprexpo|hyprexpo|hyprpm
hyprspace|hyprspace|https://github.com/KZDKM/Hyprspace|hyprspace|hyprpm
hyprglass|Hyprglass|https://github.com/hyprnux/hyprglass|hyprglass|hyprpm
scrolloverview|scrolloverview|https://github.com/yayuuu/hyprland-scroll-overview|scrolloverview|hyprpm
HyprWindowShade|HyprWindowShade|https://github.com/ManofJELLO/HyprWindowShade|HyprWindowShade|hyprpm
hyprliquid|hyprliquid|https://github.com/zaregototsukai/hyprliquid|hyprliquid|hyprpm
pyprland|pyprland|https://github.com/hyprland-community/pyprland||external
csgo-vulkan-fix|CSGO Vulkan Fix|https://github.com/hyprwm/hyprland-plugins|csgo-vulkan-fix|hyprpm
hypr-hot-edge|hypr-hot-edge|https://github.com/claychinasky/hypr-hot-edge|hypr-hot-edge|hyprpm
CATALOG

# Use an existing user catalogue if present, otherwise create the current website list.
CATALOG_FILE="${CATALOG:-$PLUGIN_DIR/catalog.txt}"
declare -a IDS=() NAMES=() REPOS=() PLUGIN_NAMES=() TYPES=()
declare -A INSTALLED=() ENABLED=() LOADED=() DESIRED=() REPO_SEEN=() SKIP_IDS=()
CURSOR=0 OFFSET=0 VIEW_ROWS=12 CHANGED=0 FAILED=0

info()    { printf '\033[1;38;5;111m[ ** ]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;38;5;214m[ !! ]\033[0m %s\n' "$*" >&2; }
error()   { printf '\033[1;38;5;196m[FAIL]\033[0m %s\n' "$*" >&2; }
success() { printf '\033[1;38;5;114m[ OK ]\033[0m %s\n' "$*"; }
die() { error "$*"; exit 1; }

cleanup() { printf '\033[?25h'; stty echo 2>/dev/null || true; }
trap cleanup EXIT INT TERM

display_banner() {
    [[ "$SHOW_BANNER" == 1 ]] || return 0
    cat <<'BANNER'
        ╦ ╦╦ ╦╔═╗╦═╗╔═╗╦  ╔═╗╔╗╔╔═╗
        ╠═╣║║║║╣ ╠╦╝║  ║  ║ ║║║║╠═╣
        ╩ ╩╚╩╝╚═╝╩╚═╚═╝╩═╝╚═╝╝╚╝╩ ╩
             HYPRLAND PLUGIN MANAGER
BANNER
}

require_commands() {
    command -v hyprpm >/dev/null 2>&1 || die "hyprpm was not found. Install the package that provides Hyprland's plugin manager."
    command -v hyprctl >/dev/null 2>&1 || warn "hyprctl not found; live-loaded plugin detection will be unavailable."
    command -v awk >/dev/null 2>&1 || die "awk is required."
    command -v stty >/dev/null 2>&1 || die "stty is required."
}

write_builtin_catalog() {
    mkdir -p "$PLUGIN_DIR" || die "Cannot create $PLUGIN_DIR"
    printf '%s\n' "$BUILTIN_CATALOG" > "$CATALOG_FILE" || die "Cannot write $CATALOG_FILE"
    info "Created website plugin catalogue: $CATALOG_FILE"
}

trim() {
    local v="$1"
    v="${v%$'\r'}"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    REPLY="$v"
}

load_catalog() {
    # Keep the default catalogue synchronized with this script version so an
    # older catalog.txt cannot silently hide newly listed website plugins.
    if [[ -z "${CATALOG:-}" ]]; then
        write_builtin_catalog
    elif [[ ! -f "$CATALOG_FILE" ]]; then
        die "Custom catalogue not found: $CATALOG_FILE"
    fi
    IDS=(); NAMES=(); REPOS=(); PLUGIN_NAMES=(); TYPES=()
    local id name repo plugin type line_no=0
    while IFS='|' read -r id name repo plugin type || [[ -n "${id:-}" ]]; do
        ((line_no += 1))
        trim "${id:-}"; id="$REPLY"
        trim "${name:-}"; name="$REPLY"
        trim "${repo:-}"; repo="$REPLY"
        trim "${plugin:-}"; plugin="$REPLY"
        trim "${type:-hyprpm}"; type="$REPLY"
        [[ -z "$id" || "$id" == \#* ]] && continue
        if [[ -z "$name" || -z "$repo" || ( "$type" == hyprpm && -z "$plugin" ) ]]; then
            warn "Skipping malformed catalogue line $line_no. Expected id|name|repo|plugin-id|type."
            continue
        fi
        [[ "$type" == external ]] || type=hyprpm
        # Turn a GitHub subdirectory URL into the repository root for hyprpm add.
        if [[ "$repo" =~ ^(https://github\.com/[^/]+/[^/]+)/tree/ ]]; then repo="${BASH_REMATCH[1]}"; fi
        IDS+=("$id"); NAMES+=("$name"); REPOS+=("$repo"); PLUGIN_NAMES+=("$plugin"); TYPES+=("$type")
    done < "$CATALOG_FILE"
    ((${#IDS[@]})) || die "No valid entries in $CATALOG_FILE"
}

refresh_state() {
    # Keep parser variables local: otherwise p overwrites install_plugin/apply_changes's
    # dynamically-scoped local plugin ID while refresh_state reads hyprpm output.
    local out p e
    INSTALLED=(); ENABLED=(); LOADED=()
    info "Reading HyprPM repository/plugin state..."
    if ! out="$(hyprpm list 2>&1)"; then
        error "hyprpm list failed: $out"
        return 1
    fi
    # hyprpm may colour its output even when captured by command substitution.
    # Strip ANSI CSI sequences before parsing, otherwise values become e.g.
    # $'\E[32mtrue' and the enabled-state comparison silently fails.
    out="$(printf '%s\n' "$out" | sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g')"
    # Pair each Plugin line with the enabled flag belonging to that plugin.
    while IFS='|' read -r p e; do
        [[ -n "$p" ]] || continue
        INSTALLED["$p"]=1
        [[ "$e" == true ]] && ENABLED["$p"]=1 || ENABLED["$p"]=0
    done < <(printf '%s\n' "$out" | awk '
        /Plugin[[:space:]]+/ {
            line=$0; sub(/^.*Plugin[[:space:]]+/, "", line); sub(/[[:space:]]*$/, "", line); p=line; next
        }
        /enabled:[[:space:]]*/ && p!="" {
            line=$0; sub(/^.*enabled:[[:space:]]*/, "", line); gsub(/[[:space:]]/, "", line); print p "|" line; p=""
        }
    ')
    if command -v hyprctl >/dev/null 2>&1; then
        out="$(hyprctl plugin list 2>/dev/null || true)"
        while IFS= read -r p; do [[ -n "$p" ]] && LOADED["$p"]=1; done < <(
            printf '%s\n' "$out" | awk '/^[[:space:]]*Plugin[[:space:]]+/ {sub(/^[[:space:]]*Plugin[[:space:]]+/, ""); sub(/[[:space:]]+by.*/, ""); print}'
        )
    fi
    return 0
}

plugin_status() {
    local p="$1" i="$2"
    if [[ "${TYPES[$i]}" == external ]]; then printf 'External tool (not HyprPM)'
    elif [[ ${LOADED[$p]:-0} == 1 ]]; then printf 'Loaded now'
    elif [[ ${ENABLED[$p]:-0} == 1 ]]; then printf 'Enabled (not loaded)'
    elif [[ ${INSTALLED[$p]:-0} == 1 ]]; then printf 'Installed / disabled'
    else printf 'Not registered in HyprPM'
    fi
}

initialize_desired() {
    local i p
    DESIRED=()
    for i in "${!IDS[@]}"; do
        [[ "${TYPES[$i]}" == external ]] && continue
        p="${PLUGIN_NAMES[$i]}"
        DESIRED["${IDS[$i]}"]="${ENABLED[$p]:-0}"
        [[ ${LOADED[$p]:-0} == 1 ]] && DESIRED["${IDS[$i]}"]=1
    done
}

draw_menu() {
    local i p status mark end
    clear; display_banner
    printf '\n  Select the plugins you want ENABLED\n'
    printf '  Space toggles; Enter applies; Esc cancels.\n'
    printf '  Website catalogue: %d entries\n\n' "${#IDS[@]}"
    local lines
    lines=$(tput lines 2>/dev/null || printf 24)
    VIEW_ROWS=$((lines - 10)); (( VIEW_ROWS < 5 )) && VIEW_ROWS=5
    (( CURSOR < OFFSET )) && OFFSET=$CURSOR
    (( CURSOR >= OFFSET + VIEW_ROWS )) && OFFSET=$((CURSOR - VIEW_ROWS + 1))
    end=$((OFFSET + VIEW_ROWS)); (( end > ${#IDS[@]} )) && end=${#IDS[@]}
    for ((i=OFFSET; i<end; i++)); do
        p="${PLUGIN_NAMES[$i]}"; status="$(plugin_status "$p" "$i")"; mark=' '
        if [[ "${TYPES[$i]}" == external ]]; then mark='-'
        elif [[ ${DESIRED[${IDS[$i]}]:-0} == 1 ]]; then mark='x'; fi
        if (( i == CURSOR )); then
            printf '  \033[1;38;5;183m> [%s] %-27.27s\033[0m \033[2m(%s)\033[0m\n' "$mark" "${NAMES[$i]}" "$status"
        else
            printf '    [%s] %-27.27s \033[2m(%s)\033[0m\n' "$mark" "${NAMES[$i]}" "$status"
        fi
    done
    printf '\n  \033[2m[x] selected  [-] external/non-HyprPM entry\033[0m\n'
}

read_key() {
    local key seq
    IFS= read -rsn1 key || return 1
    case "$key" in
        $'\x1b')
            if IFS= read -rsn1 -t 0.12 seq; then
                [[ "$seq" == '[' ]] || { REPLY_KEY=OTHER; return 0; }
                IFS= read -rsn1 -t 0.12 seq || seq=''
                case "$seq" in A) REPLY_KEY=UP;; B) REPLY_KEY=DOWN;; *) REPLY_KEY=OTHER;; esac
            else REPLY_KEY=ESC; fi ;;
        ' ') REPLY_KEY=SPACE;; '') REPLY_KEY=ENTER;; *) REPLY_KEY=OTHER;;
    esac
}

selection_menu() {
    while true; do
        draw_menu; read_key || return 1
        case "$REPLY_KEY" in
            UP) (( CURSOR > 0 )) && CURSOR=$((CURSOR - 1));;
            DOWN) (( CURSOR < ${#IDS[@]} - 1 )) && CURSOR=$((CURSOR + 1));;
            SPACE)
                if [[ "${TYPES[$CURSOR]}" == external ]]; then
                    warn "${NAMES[$CURSOR]} is listed on the website, but it is not a HyprPM shared-object plugin."
                else
                    local id="${IDS[$CURSOR]}"
                    if [[ ${DESIRED[$id]:-0} == 1 ]]; then DESIRED["$id"]=0; else DESIRED["$id"]=1; fi
                fi ;;
            ENTER) return 0;; ESC) return 1;;
        esac
    done
}

run_hyprpm() {
    printf '\n\033[1;38;5;111m$ hyprpm'; printf ' %q' "$@"; printf '\033[0m\n'
    hyprpm "$@"
}

# Same plugin ID in multiple catalogue entries (the two hyprexpo forks) cannot
# be enabled simultaneously. Keep the user's first selected fork and skip the other.
check_duplicate_selections() {
    local i j p
    SKIP_IDS=()
    for i in "${!IDS[@]}"; do
        [[ "${TYPES[$i]}" == external || ${DESIRED[${IDS[$i]}]:-0} != 1 ]] && continue
        p="${PLUGIN_NAMES[$i]}"
        for ((j=i+1; j<${#IDS[@]}; j++)); do
            [[ "${TYPES[$j]}" == external || ${DESIRED[${IDS[$j]}]:-0} != 1 ]] && continue
            if [[ "${PLUGIN_NAMES[$j]}" == "$p" ]]; then
                warn "${NAMES[$i]} and ${NAMES[$j]} share HyprPM ID '$p'; only one fork can be selected. Skipping ${NAMES[$j]}."
                SKIP_IDS["${IDS[$j]}"]=1
            fi
        done
    done
}

install_plugin() {
    local i="$1" p="${PLUGIN_NAMES[$1]}" repo="${REPOS[$1]}" add_ok=0
    info "Preparing ${NAMES[$i]} from $repo"
    # Add each repository at most once per run. If already registered, HyprPM
    # may report that; state is re-read before deciding whether this is a failure.
    if [[ ${REPO_SEEN[$repo]:-0} != 1 ]]; then
        REPO_SEEN["$repo"]=1
        run_hyprpm add "$repo" && add_ok=1 || true
    else
        info "Repository already processed in this run; not adding it again."
    fi
    refresh_state || return 1
    if [[ ${INSTALLED[$p]:-0} == 1 ]]; then
        success "${NAMES[$i]} is registered in HyprPM."
        return 0
    fi
    if [[ $add_ok == 0 ]]; then
        warn "HyprPM did not register '$p'. This repository may not expose it in its current hyprpm.toml."
    else
        warn "Repository was added, but '$p' is not present in 'hyprpm list'."
    fi
    warn "The website listing confirms the repository link, not HyprPM compatibility or a matching plugin ID."
    return 1
}

apply_changes() {
    local i p want have_installed have_enabled
    clear; display_banner
    printf '\n  Applying selected plugin states...\n'
    refresh_state || return 1
    REPO_SEEN=()
    check_duplicate_selections
    for i in "${!IDS[@]}"; do
        [[ "${TYPES[$i]}" == external || ${SKIP_IDS[${IDS[$i]}]:-0} == 1 ]] && continue
        p="${PLUGIN_NAMES[$i]}"; want="${DESIRED[${IDS[$i]}]:-0}"
        have_installed="${INSTALLED[$p]:-0}"; have_enabled="${ENABLED[$p]:-0}"
        # A currently loaded plugin is already active; don't issue redundant enable.
        if [[ "$want" == 1 && ( "$have_enabled" == 1 || ${LOADED[$p]:-0} == 1 ) ]]; then continue; fi
        if [[ "$want" == 0 && "$have_enabled" != 1 ]]; then continue; fi
        printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        info "${NAMES[$i]}"
        if [[ "$want" == 1 ]]; then
            if [[ "$have_installed" != 1 ]]; then
                install_plugin "$i" || { warn "Skipping enable for ${NAMES[$i]} (not available through current HyprPM repository metadata)."; FAILED=1; continue; }
            fi
            refresh_state || { FAILED=1; continue; }
            if [[ ${ENABLED[$p]:-0} != 1 && ${LOADED[$p]:-0} != 1 ]]; then
                if run_hyprpm enable "$p"; then CHANGED=1; success "Enabled ${NAMES[$i]}."; else FAILED=1; error "Could not enable ${NAMES[$i]}."; fi
            fi
        else
            if run_hyprpm disable "$p"; then CHANGED=1; success "Disabled ${NAMES[$i]}."; else FAILED=1; error "Could not disable ${NAMES[$i]}."; fi
        fi
    done
    if [[ "$CHANGED" == 1 ]]; then
        printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        info "Reloading plugins in the running Hyprland session..."
        run_hyprpm reload && success "hyprpm reload completed." || { FAILED=1; error "hyprpm reload failed."; }
    else info "No HyprPM state changes were applied."; fi
    printf '\n'
    [[ "$FAILED" == 1 ]] && warn "Some selected entries could not be applied. See the messages above and log." || success "Plugin operation completed."
}

main() {
    [[ -t 0 && -t 1 ]] || die "Run this script directly in a terminal; it needs interactive keyboard input."
    require_commands
    mkdir -p "$LOG_DIR" "$PLUGIN_DIR" 2>/dev/null || die "Could not create plugin/log directories."
    if command -v tee >/dev/null 2>&1; then exec > >(tee -a "$LOG_FILE") 2>&1; info "Log: $LOG_FILE"; fi
    load_catalog
    refresh_state || die "Could not read HyprPM state."
    initialize_desired
    if ! selection_menu; then clear; info "Cancelled. No changes were applied."; return 0; fi
    apply_changes
    printf '\nPress any key to close...'; IFS= read -rsn1 || true; printf '\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi


