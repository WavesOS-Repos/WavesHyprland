#!/usr/bin/env bash
# WavesOS keybind editor (terminal)
set -euo pipefail

HYPR_DIR="${HYPR_DIR:-$HOME/.config/hypr}"
KEYBINDS="${HYPR_DIR}/configs/keybinds.lua"
BACKUP="${KEYBINDS}.bak-keybind-editor"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

[[ -f "$KEYBINDS" ]] || { echo "Missing $KEYBINDS"; exit 1; }
[[ -t 0 && -t 1 ]] || { echo "Run in a terminal (kitty)."; exit 1; }

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -t 2000 "Keybinds" "$1" || true
}

pause() {
    echo
    read -r -n1 -p "Press any key..." _
    echo
}

draw_header() {
    clear
    echo -e "${BOLD}══════════════════════════════════════${NC}"
    echo -e "${BOLD}  Keybind editor${NC}"
    echo -e "${BOLD}══════════════════════════════════════${NC}"
    echo
}

normalize_chord() {
    local s="$1"
    s=$(echo "$s" | tr '[:lower:]' '[:upper:]')
    s=$(echo "$s" | sed -E \
        -e 's/MAINMOD/SUPER/g' \
        -e 's/MOD4/SUPER/g' \
        -e 's/WIN/SUPER/g' \
        -e 's/ENTER/RETURN/g' \
        -e 's/ESC$/ESCAPE/' \
        -e 's/[^A-Z0-9+]/+/g' \
        -e 's/\++/+/g' \
        -e 's/^\+//' \
        -e 's/\+$//')
    echo "$s"
}

chord_to_lua() {
    local raw
    raw=$(normalize_chord "$1")
    [[ -z "$raw" ]] && { echo '""'; return; }

    local IFS='+'
    local -a parts=()
    read -ra parts <<< "$raw"

    local use_mod=0
    local -a out=()
    local p
    for p in "${parts[@]}"; do
        case "$p" in
            SUPER|WIN|MOD4|MOD) use_mod=1 ;;
            ENTER) out+=("RETURN") ;;
            ESC) out+=("ESCAPE") ;;
            "") ;;
            *) out+=("$p") ;;
        esac
    done

    local joined=""
    if ((${#out[@]})); then
        joined=$(IFS=' + '; echo "${out[*]}")
    fi

    if [[ $use_mod -eq 1 ]]; then
        if [[ -n "$joined" ]]; then
            printf 'mainMod .. " + %s"' "$joined"
        else
            printf 'mainMod .. " + INVALID"'
        fi
    else
        printf '"%s"' "$joined"
    fi
}

list_binds() {
    python3 - "$KEYBINDS" <<'PY'
import re, sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines()

def pretty_from_lua_key(key: str) -> str:
    k = key.strip()
    m = re.match(r'^mainMod\s*\.\.\s*"\s*\+\s*(.+)"\s*$', k)
    if m:
        parts = [p.strip().strip('"').upper() for p in re.split(r'\s*\+\s*', m.group(1).strip()) if p.strip()]
        return "SUPER+" + "+".join(parts) if parts else "SUPER"
    # mainMod .. " + " .. key  (workspace loop — show template)
    m = re.match(r'^mainMod\s*\.\.\s*"\s*\+\s*"\s*\.\.\s*key\s*$', k)
    if m:
        return "SUPER+0-9 (loop)"
    m = re.match(r'^mainMod\s*\.\.\s*"\s*\+\s*SHIFT\s*\+\s*"\s*\.\.\s*key\s*$', k)
    if m:
        return "SUPER+SHIFT+0-9 (loop)"
    m = re.match(r'^mainMod\s*\.\.\s*"\s*\+\s*ALT\s*\+\s*"\s*\.\.\s*key\s*$', k)
    if m:
        return "SUPER+ALT+0-9 (loop)"
    m = re.match(r'^"(.*)"\s*$', k)
    if m:
        parts = [p.strip().upper() for p in re.split(r'\s*\+\s*', m.group(1).strip()) if p.strip()]
        return "+".join(parts)
    if re.match(r'^mainMod\s*$', k):
        return "SUPER"
    k2 = re.sub(r'mainMod\s*\.\.\s*', 'SUPER+', k)
    k2 = k2.replace('"', '').replace(' ', '')
    return k2.upper() if k2 else "?"

def extract_binds(lines):
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        if line.strip().startswith("--"):
            i += 1
            continue
        if "hl.bind" not in line:
            i += 1
            continue
        # Start of bind — may span lines
        if not re.search(r'hl\.bind\s*\(', line):
            i += 1
            continue
        start = i
        buf = line
        # If this line already has balanced parens after hl.bind, it's one-line
        def balanced(s):
            # count parens outside strings
            inq = False
            depth = 0
            started = False
            for j, c in enumerate(s):
                if c == '"' and (j == 0 or s[j-1] != '\\'):
                    inq = not inq
                elif not inq:
                    if c == '(':
                        depth += 1
                        started = True
                    elif c == ')':
                        depth -= 1
            return started and depth <= 0

        while not balanced(buf) and i + 1 < n:
            i += 1
            buf += "\n" + lines[i]
        # strip comment only on last line conceptually — remove -- comments carefully
        # Work on full buf
        # Find hl.bind( ... )
        m = re.search(r'hl\.bind\s*\(', buf)
        if not m:
            i += 1
            continue
        start_paren = m.end() - 1  # index of (
        inq = False
        depth = 0
        end_paren = -1
        for j in range(start_paren, len(buf)):
            c = buf[j]
            if c == '"' and (j == 0 or buf[j-1] != '\\'):
                inq = not inq
            elif not inq:
                if c == '(':
                    depth += 1
                elif c == ')':
                    depth -= 1
                    if depth == 0:
                        end_paren = j
                        break
        if end_paren < 0:
            i += 1
            continue
        inner = buf[start_paren + 1 : end_paren]
        # first arg split
        inq = False
        depth = 0
        split_at = -1
        for j, c in enumerate(inner):
            if c == '"' and (j == 0 or inner[j-1] != '\\'):
                inq = not inq
            elif not inq:
                if c == '(':
                    depth += 1
                elif c == ')':
                    depth -= 1
                elif c == ',' and depth == 0:
                    split_at = j
                    break
        if split_at < 0:
            i += 1
            continue
        key = inner[:split_at].strip()
        rest = inner[split_at + 1 :].strip()
        # skip function() binds for "change key" display still show them
        pretty = pretty_from_lua_key(key)
        action = re.sub(r'\s+', ' ', rest)
        if len(action) > 70:
            action = action[:67] + "..."
        # line number = start line (1-based)
        print(f"{start + 1}\t{pretty}\t{key}\t{action}")
        i += 1

extract_binds(lines)
PY
}

used_keys() {
    list_binds | while IFS=$'\t' read -r lineno pretty key rest; do
        normalize_chord "$pretty"
    done | sort -u
}

suggest_free_keys() {
    local used
    used=$(used_keys)
    local L c cand
    for L in {A..Z} {0..9}; do
        for c in \
            "SUPER+$L" \
            "SUPER+SHIFT+$L" \
            "SUPER+ALT+$L" \
            "SUPER+CTRL+$L" \
            "SUPER+CTRL+SHIFT+$L"
        do
            cand=$(normalize_chord "$c")
            if ! grep -qxF "$cand" <<< "$used"; then
                echo "$cand"
            fi
        done
    done
}

replace_bind_key() {
    local lineno="$1" new_lua_key="$2"
    cp -p "$KEYBINDS" "$BACKUP"
    python3 - "$KEYBINDS" "$lineno" "$new_lua_key" <<'PY'
import re, sys
path, lineno_s, new_key = sys.argv[1], int(sys.argv[2]), sys.argv[3]
lines = open(path, encoding="utf-8").read().splitlines(True)
start = lineno_s - 1
if start < 0 or start >= len(lines):
    sys.exit("bad line")

# Re-join multi-line bind starting at start
buf = lines[start]
idx = start

def balanced(s):
    inq = False
    depth = 0
    started = False
    for j, c in enumerate(s):
        if c == '"' and (j == 0 or s[j-1] != '\\'):
            inq = not inq
        elif not inq:
            if c == '(':
                depth += 1
                started = True
            elif c == ')':
                depth -= 1
    return started and depth <= 0

while not balanced(buf) and idx + 1 < len(lines):
    idx += 1
    buf += lines[idx]

m = re.search(r'hl\.bind\s*\(', buf)
if not m:
    sys.exit("no bind")
start_paren = m.end() - 1
inq = False
depth = 0
end_paren = -1
for j in range(start_paren, len(buf)):
    c = buf[j]
    if c == '"' and (j == 0 or buf[j-1] != '\\'):
        inq = not inq
    elif not inq:
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                end_paren = j
                break
if end_paren < 0:
    sys.exit("no end")
inner = buf[start_paren + 1 : end_paren]
inq = False
depth = 0
split_at = -1
for j, c in enumerate(inner):
    if c == '"' and (j == 0 or inner[j-1] != '\\'):
        inq = not inq
    elif not inq:
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
        elif c == ',' and depth == 0:
            split_at = j
            break
if split_at < 0:
    sys.exit("no comma")
rest = inner[split_at:]  # , ...
prefix = buf[: start_paren + 1]
suffix = buf[end_paren + 1 :]  # after )
# rebuild as single-line bind for clarity
indent = re.match(r'^(\s*)', lines[start]).group(1)
new_block = f"{indent}hl.bind({new_key}{rest})\n"
# if original had only trailing stuff after ) on last piece
# replace lines start..idx with new_block
new_lines = lines[:start] + [new_block] + lines[idx + 1 :]
open(path, "w", encoding="utf-8").writelines(new_lines)
PY
}

remove_bind_at_line() {
    local lineno="$1"
    cp -p "$KEYBINDS" "$BACKUP"
    python3 - "$KEYBINDS" "$lineno" <<'PY'
import re, sys
path, lineno_s = sys.argv[1], int(sys.argv[2])
lines = open(path, encoding="utf-8").read().splitlines(True)
start = lineno_s - 1
if start < 0 or start >= len(lines):
    sys.exit("bad line")

buf = lines[start]
idx = start

def balanced(s):
    inq = False
    depth = 0
    started = False
    for j, c in enumerate(s):
        if c == '"' and (j == 0 or s[j-1] != '\\'):
            inq = not inq
        elif not inq:
            if c == '(':
                depth += 1
                started = True
            elif c == ')':
                depth -= 1
    return started and depth <= 0

while not balanced(buf) and idx + 1 < len(lines):
    idx += 1
    buf += lines[idx]

# Also drop a single immediately preceding "-- added by keybind-editor" comment line
drop_from = start
if start > 0 and re.match(r'^\s*--\s*added by keybind-editor', lines[start - 1]):
    drop_from = start - 1

new_lines = lines[:drop_from] + lines[idx + 1:]
open(path, "w", encoding="utf-8").writelines(new_lines)
PY
}

remove_existing() {
    mapfile -t ROWS < <(list_binds)
    ((${#ROWS[@]})) || { echo "No one-line binds found."; pause; return; }

    draw_header
    echo -e "${DIM}Pick a number to REMOVE${NC}"
    echo
    local i=0 lineno pretty key rest
    for row in "${ROWS[@]}"; do
        i=$((i + 1))
        IFS=$'\t' read -r lineno pretty key rest <<< "$row"
        printf "  ${CYAN}%2d${NC}  %-28s  %s\n" "$i" "$pretty" "$rest"
    done
    echo
    read -r -p "Number (empty = back): " num
    [[ -z "$num" ]] && return
    [[ "$num" =~ ^[0-9]+$ ]] || return
    (( num >= 1 && num <= ${#ROWS[@]} )) || return

    IFS=$'\t' read -r lineno pretty key rest <<< "${ROWS[$((num - 1))]}"

    clear
    echo
    echo -e "${RED}${BOLD}"
    cat <<'WARN'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   WARNING: YOU ARE ABOUT TO DELETE A KEYBIND                 ║
║                                                              ║
║   This cannot be undone except by restoring the backup:      ║
║   keybinds.lua.bak-keybind-editor                            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
WARN
    echo -e "${NC}"
    echo -e "  Key:    ${BOLD}${pretty}${NC}"
    echo -e "  Action: ${rest}"
    echo
    echo -e "${RED}${BOLD}Type exactly:  DELETE${NC}"
    echo -e "${DIM}(anything else cancels)${NC}"
    echo
    read -r -p "> " confirm
    if [[ "$confirm" != "DELETE" ]]; then
        echo -e "${GREEN}Cancelled. Nothing was removed.${NC}"
        pause
        return
    fi

    remove_bind_at_line "$lineno"
    hyprctl reload >/dev/null 2>&1 || true
    echo -e "${GREEN}Removed ${pretty}${NC}"
    notify "Removed keybind $pretty"
    pause
}

append_bind() {
    local chord="$1" cmd="$2"
    local lua_key cmd_esc
    lua_key=$(chord_to_lua "$chord")
    if [[ "$lua_key" == *INVALID* ]]; then
        echo -e "${RED}Invalid key: use e.g. SUPER+K or SUPER+SHIFT+E${NC}"
        return 1
    fi
    cmd_esc=${cmd//\\/\\\\}
    cmd_esc=${cmd_esc//\"/\\\"}
    cp -p "$KEYBINDS" "$BACKUP"
    {
        echo ""
        echo "-- added by keybind-editor: $chord → $cmd"
        echo "hl.bind(${lua_key}, hl.dsp.exec_cmd(\"${cmd_esc}\"))"
    } >> "$KEYBINDS"
}

change_existing() {
    mapfile -t ROWS < <(list_binds)
    ((${#ROWS[@]})) || { echo "No one-line binds found."; pause; return; }

    draw_header
    echo -e "${DIM}Pick a number to change its key${NC}"
    echo
    local i=0 lineno pretty key rest
    for row in "${ROWS[@]}"; do
        i=$((i + 1))
        IFS=$'\t' read -r lineno pretty key rest <<< "$row"
        printf "  ${CYAN}%2d${NC}  %-28s  %s\n" "$i" "$pretty" "$rest"
    done
    echo
    read -r -p "Number (empty = back): " num
    [[ -z "$num" ]] && return
    [[ "$num" =~ ^[0-9]+$ ]] || return
    (( num >= 1 && num <= ${#ROWS[@]} )) || return

    IFS=$'\t' read -r lineno pretty key rest <<< "${ROWS[$((num - 1))]}"
    echo
    echo -e "Current key: ${BOLD}$pretty${NC}"
    echo -e "${DIM}Examples: SUPER+K   SUPER+SHIFT+E   CTRL+ALT+T${NC}"
    read -r -p "New key: " new_chord
    [[ -z "$new_chord" ]] && return

    new_chord=$(normalize_chord "$new_chord")
    local lua_key
    lua_key=$(chord_to_lua "$new_chord")
    if [[ "$lua_key" == *INVALID* ]]; then
        echo -e "${RED}Invalid chord.${NC}"
        pause
        return
    fi

    local used u
    used=$(used_keys)
    if grep -qxF "$new_chord" <<< "$used"; then
        u=$(normalize_chord "$pretty")
        if [[ "$new_chord" != "$u" ]]; then
            echo -e "${RED}Key already used: $new_chord${NC}"
            read -r -p "Use it anyway? [y/N] " yn
            [[ "$yn" =~ ^[yY]$ ]] || { pause; return; }
        fi
    fi

    replace_bind_key "$lineno" "$lua_key"
    hyprctl reload >/dev/null 2>&1 || true
    echo -e "${GREEN}Updated → $new_chord${NC}"
    notify "Keybind → $new_chord"
    pause
}

add_new() {
    draw_header
    echo -e "${BOLD}Command to run${NC}"
    echo -e "${DIM}e.g. kitty | firefox | ~/.config/hypr/scripts/foo.sh${NC}"
    read -r -p "Command: " cmd
    [[ -z "$cmd" ]] && return

    echo
    echo -e "${BOLD}Key${NC}"
    echo "  1) Pick from free keys"
    echo "  2) Type your own"
    read -r -p "Choice [1/2]: " mode

    local chord=""
    if [[ "$mode" == "2" ]]; then
        echo -e "${DIM}Examples: SUPER+K   SUPER+SHIFT+T   SUPER+ALT+W${NC}"
        read -r -p "Key: " chord
    else
        mapfile -t FREE < <(suggest_free_keys | head -n 60)
        if ((${#FREE[@]} == 0)); then
            echo "No free suggestions; type a key instead."
            read -r -p "Key: " chord
        else
            echo
            local i=0
            for c in "${FREE[@]}"; do
                i=$((i + 1))
                printf "  ${CYAN}%2d${NC}  %s\n" "$i" "$c"
            done
            echo
            read -r -p "Number (or type a key): " pick
            if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#FREE[@]} )); then
                chord="${FREE[$((pick - 1))]}"
            else
                chord="$pick"
            fi
        fi
    fi
    [[ -z "$chord" ]] && return

    chord=$(normalize_chord "$chord")
    if grep -qxF "$chord" <<< "$(used_keys)"; then
        echo -e "${RED}Key already used: $chord${NC}"
        pause
        return
    fi

    if append_bind "$chord" "$cmd"; then
        hyprctl reload >/dev/null 2>&1 || true
        echo -e "${GREEN}Added $chord → $cmd${NC}"
        notify "Added $chord"
    fi
    pause
}

while true; do
    draw_header
    echo "  1) Change existing keybind"
    echo "  2) Add new command keybind"
    echo "  3) Remove keybind"
    echo "  4) Open keybinds.lua in editor"
    echo "  q) Quit"
    echo
    read -r -p "Select: " choice
    case "$choice" in
        1) change_existing ;;
        2) add_new ;;
	3) remove_existing ;;
        4) "${EDITOR:-nano}" "$KEYBINDS" ;;
        q|Q) break ;;
    esac
done

clear
echo "Done."
