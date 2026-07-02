#!/usr/bin/env bash
set -uo pipefail

MAX_ITERS=50
MAX_HOURS=""
PERMISSIONS="dontAsk"
BRAIN_OVERRIDE=""
BRAWN_OVERRIDE=""

usage() {
    echo "Usage: architect-loop [--max-iters N] [--max-hours H] [--permissions MODE] [--brain CLI/MODEL[:EFFORT]] [--brawn CLI/MODEL[:EFFORT]]" >&2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --max-iters) shift; MAX_ITERS="${1:-}";;
        --max-hours) shift; MAX_HOURS="${1:-}";;
        --permissions) shift; PERMISSIONS="${1:-}";;
        --brain) shift; BRAIN_OVERRIDE="${1:-}";;
        --brawn) shift; BRAWN_OVERRIDE="${1:-}";;
        -h|--help) usage; exit 0;;
        *) usage; exit 2;;
    esac
    [ -n "${1:-}" ] || { usage; exit 2; }
    shift
done

REPO="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$REPO" ] || REPO="$(pwd -P)"
LOOP_DIR="$REPO/.architect/loop"
TMP_DIR="$REPO/.architect/tmp/loop"
mkdir -p "$LOOP_DIR" "$TMP_DIR"
INDEX="$LOOP_DIR/loop.log"
HANDOFF="$REPO/docs/HANDOFF.md"
STOP_FILE="$REPO/docs/STOP"
START_EPOCH="$(date +%s)"

warn() { echo "WARNING: $*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }
valid_role() { [[ "$1" =~ ^(claude|codex)/[^[:space:]/#]+(:[^[:space:]/#]+)?$ ]]; }

read_config() {
    local file="$1" key value
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        if [[ "$line" =~ ^[[:space:]]*(brain|brawn)[[:space:]]*=[[:space:]]*([^[:space:]]+)[[:space:]]*$ ]]; then
            key="${BASH_REMATCH[1]}"; value="${BASH_REMATCH[2]}"
            if valid_role "$value"; then
                [ "$key" = "brain" ] && [ -z "$BRAIN" ] && BRAIN="$value"
                [ "$key" = "brawn" ] && [ -z "$BRAWN" ] && BRAWN="$value"
            else
                warn "$file: invalid $key value '$value'"
            fi
        elif [[ "$line" =~ ^[[:space:]]*([^=[:space:]]+)[[:space:]]*= ]]; then
            warn "$file: unknown config key '${BASH_REMATCH[1]}'"
        else
            warn "$file: ignored invalid config line '$line'"
        fi
    done < "$file"
}

pick_default_brain() {
    if command -v claude >/dev/null 2>&1; then echo "claude/best"; return; fi
    if command -v codex >/dev/null 2>&1; then echo "codex/best"; return; fi
    die "neither claude nor codex is on PATH"
}

split_role() {
    ROLE_CLI="${1%%/*}"
    local rest="${1#*/}"
    ROLE_MODEL="${rest%%:*}"
    ROLE_EFFORT=""
    [[ "$rest" == *:* ]] && ROLE_EFFORT="${rest#*:}"
}

resolve_role() {
    split_role "$1"
    case "$ROLE_CLI/$ROLE_MODEL" in
        claude/best) ROLE_MODEL="opus"; [ -n "$ROLE_EFFORT" ] || ROLE_EFFORT="xhigh";;
        claude/tier-down) ROLE_MODEL="sonnet"; [ -n "$ROLE_EFFORT" ] || ROLE_EFFORT="high";;
        codex/best) ROLE_MODEL="gpt-5.5"; [ -n "$ROLE_EFFORT" ] || ROLE_EFFORT="xhigh";;
        codex/tier-down) ROLE_MODEL="gpt-5.5"; [ -n "$ROLE_EFFORT" ] || ROLE_EFFORT="high";;
    esac
}

tier_down() {
    resolve_role "$1"
    if [ "$ROLE_CLI" = "claude" ]; then
        case "$ROLE_MODEL" in
            sonnet) echo "claude/haiku:high";;
            haiku) echo "claude/haiku:high";;
            *) echo "claude/sonnet:high";;
        esac
    else
        echo "codex/$ROLE_MODEL:high"
    fi
}

head_sha() { git -C "$REPO" rev-parse HEAD 2>/dev/null || true; }
handoff_mtime() { [ -f "$HANDOFF" ] && (stat -c %Y "$HANDOFF" 2>/dev/null || stat -f %m "$HANDOFF" 2>/dev/null) || true; }

event_sizes() {
    [ -d "$REPO/.architect" ] || return 0
    while IFS= read -r file; do
        size="$(wc -c < "$file" | tr -d '[:space:]')"
        printf '%s\t%s\n' "$file" "$size"
    done < <(find "$REPO/.architect" -type f \( -name '*.json' -o -name '*.jsonl' \) 2>/dev/null | sort)
}

events_grew() {
    local before="$1" after="$2" file size old
    while IFS=$'\t' read -r file size; do
        [ -n "$file" ] || continue
        old="$(awk -F '\t' -v f="$file" '$1==f {print $2}' "$before")"
        [ -n "$old" ] || old=0
        [ "$size" -gt "$old" ] && return 0
    done < "$after"
    return 1
}

sentinel_line() {
    [ -f "$HANDOFF" ] || return 1
    mapfile -t lines < <(grep '^LOOP:' "$HANDOFF" || true)
    [ "${#lines[@]}" -eq 1 ] || return 1
    [[ "${lines[0]}" =~ ^LOOP:\ (CONTINUE|WAIT\ [0-9]+(\ \(.+\))?|STOP\ \(.+\))$ ]] || return 1
    echo "${lines[0]}"
}

stop_with_tail() {
    local reason="$1" log="${2:-}"
    echo "STOP: $reason"
    if [ -n "$log" ] && [ -f "$log" ]; then
        echo "Last log tail:"
        tail -n 20 "$log"
    fi
    exit 0
}

build_codex_prompt() {
    local out="$1" skill="$REPO/skills/architect/SKILL.md"
    [ -f "$skill" ] || skill="$HOME/.claude/skills/architect/SKILL.md"
    [ -f "$skill" ] || die "architect skill not found in repo or ~/.claude/skills"
    {
        echo "<!-- PENDING-CANARY: \$skill invocation in codex exec is unverified; prompt inlines skill text. -->"
        echo "You are running under architect-loop. Execute the architect skill for this repository."
        echo
        echo "<architect-skill>"
        cat "$skill"
        echo "</architect-skill>"
    } > "$out"
}

invoke_brain() {
    local brain="$1" log="$2" prompt="$3" status
    resolve_role "$brain"
    if [ "$ROLE_CLI" = "claude" ]; then
        local cmd=(claude -p "/architect" --model "$ROLE_MODEL")
        [ -n "$ROLE_EFFORT" ] && cmd+=(--effort "$ROLE_EFFORT")
        if [ "$PERMISSIONS" = "bypass" ]; then
            cmd+=(--dangerously-skip-permissions)
        else
            cmd+=(--permission-mode "$PERMISSIONS")
        fi
        env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT ARCHITECT_LOOP=1 "${cmd[@]}" 2>&1 | tee "$log"
        status="${PIPESTATUS[0]}"
    else
        local cmd=(codex exec -C "$REPO" --sandbox danger-full-access -m "$ROLE_MODEL")
        [ -n "$ROLE_EFFORT" ] && cmd+=(-c "model_reasoning_effort=\"$ROLE_EFFORT\"")
        cmd+=(-)
        ARCHITECT_LOOP=1 "${cmd[@]}" < "$prompt" 2>&1 | tee "$log"
        status="${PIPESTATUS[0]}"
    fi
    return "$status"
}

BRAIN="$BRAIN_OVERRIDE"
BRAWN="$BRAWN_OVERRIDE"
read_config "$REPO/.architect/config"
read_config "$HOME/.architect/config"
[ -n "$BRAIN" ] || BRAIN="$(pick_default_brain)"
[ -n "$BRAWN" ] || BRAWN="$(tier_down "$BRAIN")"
valid_role "$BRAIN" || die "invalid brain '$BRAIN'"
valid_role "$BRAWN" || die "invalid brawn '$BRAWN'"
split_role "$BRAIN"; command -v "$ROLE_CLI" >/dev/null 2>&1 || die "brain CLI '$ROLE_CLI' not on PATH"
split_role "$BRAWN"; command -v "$ROLE_CLI" >/dev/null 2>&1 || { warn "brawn CLI '$ROLE_CLI' not on PATH; falling back to $(tier_down "$BRAIN")"; BRAWN="$(tier_down "$BRAIN")"; }
[ -f "$HANDOFF" ] || warn "docs/HANDOFF.md missing; first iteration must bootstrap it"

cheap_next=0
no_progress=0
nonzero=0
last_log=""

for ((iter=1; iter<=MAX_ITERS; iter++)); do
    [ ! -f "$STOP_FILE" ] || stop_with_tail "docs/STOP present: $(cat "$STOP_FILE")" "$last_log"
    if [ -n "$MAX_HOURS" ]; then
        elapsed=$(( $(date +%s) - START_EPOCH ))
        limit="$(awk -v h="$MAX_HOURS" 'BEGIN {printf "%d", h * 3600}')"
        [ "$elapsed" -lt "$limit" ] || stop_with_tail "--max-hours $MAX_HOURS reached" "$last_log"
    fi
    current="$BRAIN"; [ "$cheap_next" -eq 1 ] && current="$(tier_down "$BRAIN")"
    ts="$(date -u +%Y%m%dT%H%M%SZ)"
    log="$LOOP_DIR/${iter}-${ts}.log"; last_log="$log"
    prompt="$TMP_DIR/prompt-${iter}.md"
    before_head="$(head_sha)"
    before_sentinel="$(sentinel_line 2>/dev/null || true)"
    before_mtime="$(handoff_mtime)"
    before_events="$TMP_DIR/events-before-${iter}.txt"
    after_events="$TMP_DIR/events-after-${iter}.txt"
    event_sizes > "$before_events"
    split_role "$current"
    [ "$ROLE_CLI" = "codex" ] && build_codex_prompt "$prompt"
    invoke_brain "$current" "$log" "$prompt"; status="$?"
    after_head="$(head_sha)"
    after_mtime="$(handoff_mtime)"
    event_sizes > "$after_events"
    if [ "$status" -ne 0 ]; then nonzero=$((nonzero + 1)); else nonzero=0; fi
    [ "$nonzero" -lt 5 ] || stop_with_tail "5 consecutive nonzero exits" "$log"
    [ -f "$HANDOFF" ] || stop_with_tail "docs/HANDOFF.md missing after iteration" "$log"
    [ -n "$after_mtime" ] && [ "$after_mtime" != "$before_mtime" ] || stop_with_tail "docs/HANDOFF.md untouched after iteration" "$log"
    sentinel="$(sentinel_line)" || stop_with_tail "missing or unparseable LOOP sentinel" "$log"
    progressed=0
    [ "$after_head" != "$before_head" ] && progressed=1
    [ "$sentinel" != "$before_sentinel" ] && progressed=1
    events_grew "$before_events" "$after_events" && progressed=1
    if [ "$progressed" -eq 1 ]; then no_progress=0; else no_progress=$((no_progress + 1)); fi
    [ "$no_progress" -lt 3 ] || stop_with_tail "3 consecutive no-progress iterations" "$log"
    echo "$ts iteration=$iter brain=$current brawn=$BRAWN exit=$status sentinel=\"$sentinel\" log=$log" >> "$INDEX"
    case "$sentinel" in
        "LOOP: CONTINUE") cheap_next=0;;
        LOOP:\ WAIT\ *) cheap_next=1; minutes="$(echo "$sentinel" | sed -E 's/^LOOP: WAIT ([0-9]+).*/\1/')"; sleep $((minutes * 60));;
        LOOP:\ STOP\ \(*\)) stop_with_tail "$sentinel" "$log";;
    esac
done

stop_with_tail "--max-iters $MAX_ITERS reached" "$last_log"
