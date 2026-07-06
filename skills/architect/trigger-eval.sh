#!/usr/bin/env bash
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
fixture=
start=1
limit=0
claude_bin=claude
bare=0
show_raw=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-root) root=$2; shift 2;;
    --fixture) fixture=$2; shift 2;;
    --start) start=$2; shift 2;;
    --limit) limit=$2; shift 2;;
    --claude) claude_bin=$2; shift 2;;
    --bare) bare=1; shift;;
    --show-raw) show_raw=1; shift;;
    *) printf 'unknown argument: %s\n' "$1"; exit 1;;
  esac
done

case "$root" in /*) ;; *) root="$(pwd)/$root";; esac
[ -d "$root" ] || { printf 'unreadable repo: %s\n' "$root"; exit 1; }
[ -n "$fixture" ] || fixture="$root/docs/evals/trigger-prompts.md"
case "$fixture" in /*) ;; *) fixture="$(pwd)/$fixture";; esac
[ -f "$fixture" ] || { printf 'fixture not found: %s\n' "$fixture"; exit 1; }

case "$start" in ''|*[!0-9]*) printf 'start must be a positive integer\n'; exit 1;; esac
case "$limit" in ''|*[!0-9]*) printf 'limit must be a non-negative integer\n'; exit 1;; esac
[ "$start" -ge 1 ] || { printf 'start must be >= 1\n'; exit 1; }

json_detector='
import json
import re
import sys

skill = sys.argv[1]
pattern = re.compile(r"(^|[^a-z0-9_-])/?%s([^a-z0-9_-]|$)" % re.escape(skill), re.I)

def has_skill_text(node):
    if node is None:
        return False
    if isinstance(node, str):
        return bool(pattern.search(node))
    if isinstance(node, list):
        return any(has_skill_text(item) for item in node)
    if isinstance(node, dict):
        return any(has_skill_text(value) for value in node.values())
    return False

def prop(node, *names):
    if not isinstance(node, dict):
        return None
    for name in names:
        if name in node:
            return node[name]
    return None

def reliable_event(node):
    if node is None or isinstance(node, str):
        return False
    if isinstance(node, list):
        return any(reliable_event(item) for item in node)
    if not isinstance(node, dict):
        return False

    skill_value = prop(node, "skill", "skill_name", "skillName", "invoked_skill", "invokedSkill")
    if isinstance(skill_value, str) and pattern.search(skill_value):
        return True

    type_value = prop(node, "type", "event", "event_type", "eventType")
    name_value = prop(node, "name", "tool", "tool_name", "toolName")
    type_skillish = isinstance(type_value, str) and re.search(r"(skill|tool_use|tool_call|tool-call)", type_value, re.I)
    name_skillish = isinstance(name_value, str) and re.search(r"(^Skill$|skill)", name_value, re.I)
    if (type_skillish or name_skillish) and has_skill_text(node):
        return True

    return any(reliable_event(value) for value in node.values())

for raw in sys.stdin:
    raw = raw.strip()
    if not raw:
        continue
    try:
        obj = json.loads(raw)
    except Exception:
        continue
    if reliable_event(obj):
        print("trigger")
        sys.exit(0)
print("unknown")
'

parse_fixture() {
  awk '
    /^- PROMPT: / {
      prompt = substr($0, 11)
      if ((getline skill_line) <= 0) { printf "ERROR\tincomplete prompt block at line %d\n", NR > "/dev/stderr"; exit 2 }
      if (skill_line !~ /^[[:space:]]+SKILL: (architect|architect-fast|architect-research|codebase-design|to-spec|to-issues|frozen-checks|tdd|adversarial-review|final-review)$/) { printf "ERROR\tinvalid SKILL line after prompt near line %d: %s\n", NR - 1, skill_line > "/dev/stderr"; exit 2 }
      skill = skill_line
      sub(/^[[:space:]]+SKILL: /, "", skill)
      if ((getline expect_line) <= 0) { printf "ERROR\tincomplete prompt block at line %d\n", NR > "/dev/stderr"; exit 2 }
      if (expect_line !~ /^[[:space:]]+EXPECT: (trigger|no-trigger)$/) { printf "ERROR\tinvalid EXPECT line after prompt near line %d: %s\n", NR - 2, expect_line > "/dev/stderr"; exit 2 }
      expect = expect_line
      sub(/^[[:space:]]+EXPECT: /, "", expect)
      count += 1
      printf "%d\t%s\t%s\t%s\n", count, skill, expect, prompt
      next
    }
    /^[[:space:]]+(SKILL|EXPECT):/ {
      printf "ERROR\torphaned fixture line %d: %s\n", NR, $0 > "/dev/stderr"
      exit 2
    }
  ' "$fixture"
}

rows=$(parse_fixture) || exit 1
[ -n "$rows" ] || { printf 'fixture contains no prompt blocks: %s\n' "$fixture"; exit 1; }

tmp_root="$root/.architect/tmp/trigger-evals"
mkdir -p "$tmp_root" || { printf 'could not create temp root: %s\n' "$tmp_root"; exit 1; }

printf 'FIXTURE: %s\n' "$fixture"
selected_count=$(printf '%s\n' "$rows" | awk -F '\t' -v s="$start" -v l="$limit" '$1 >= s { n += 1; if (l > 0 && n > l) next; c += 1 } END { print c + 0 }')
printf 'PROMPTS: %s\n' "$selected_count"
[ "$selected_count" -gt 0 ] || { printf 'no prompts selected from fixture\n'; exit 1; }

run_rows_file="$tmp_root/run-rows.tsv"
: > "$run_rows_file" || { printf 'could not write temp rows: %s\n' "$run_rows_file"; exit 1; }

seen=0
printf '%s\n' "$rows" | while IFS="$(printf '\t')" read -r idx skill expect prompt; do
  [ "$idx" -ge "$start" ] || continue
  seen=$((seen + 1))
  if [ "$limit" -gt 0 ] && [ "$seen" -gt "$limit" ]; then continue; fi
  if [ "$bare" -eq 1 ]; then
    printf 'COMMAND[%s]: %s -p "%s" --bare --output-format stream-json --verbose --include-hook-events --no-session-persistence --permission-mode dontAsk --disallowedTools Bash,Edit,Write\n' "$idx" "$claude_bin" "$(printf '%s' "$prompt" | sed 's/"/\\"/g')"
  else
    printf 'COMMAND[%s]: %s -p "%s" --output-format stream-json --verbose --include-hook-events --no-session-persistence --permission-mode dontAsk --disallowedTools Bash,Edit,Write\n' "$idx" "$claude_bin" "$(printf '%s' "$prompt" | sed 's/"/\\"/g')"
  fi
  old_tmp=${TMPDIR:-}
  TMPDIR="$tmp_root"
  export TMPDIR
  # stdin from /dev/null: an inherited open pipe makes claude -p wait on stdin and fail
  if [ "$bare" -eq 1 ]; then
    output=$("$claude_bin" -p "$prompt" --bare --output-format stream-json --verbose --include-hook-events --no-session-persistence --permission-mode dontAsk --disallowedTools Bash,Edit,Write < /dev/null 2>&1)
  else
    output=$("$claude_bin" -p "$prompt" --output-format stream-json --verbose --include-hook-events --no-session-persistence --permission-mode dontAsk --disallowedTools Bash,Edit,Write < /dev/null 2>&1)
  fi
  code=$?
  if [ -n "$old_tmp" ]; then TMPDIR=$old_tmp; export TMPDIR; else unset TMPDIR; fi
  # Explicit "/<skill> ..." prompts expand harness-side (no Skill tool_use
  # event); "Unknown command: /<skill>" is the definitive negative there.
  # event codes: 0 unknown, 1 structural Skill event, 2 explicit trigger,
  # 3 explicit no-trigger.
  event=0
  explicit=0
  case "$prompt" in "/$skill"|"/$skill "*) explicit=1;; esac
  if [ "$code" -eq 0 ]; then
    if [ "$explicit" -eq 1 ]; then
      if printf '%s\n' "$output" | grep -q "Unknown command: /$skill"; then event=3; else event=2; fi
    elif command -v python3 >/dev/null 2>&1; then
      detected=$(printf '%s\n' "$output" | python3 -c "$json_detector" "$skill" 2>/dev/null || printf unknown)
      [ "$detected" = trigger ] && event=1
    else
      printf 'JSON_DETECTOR[%s]: python3 not found; Skill event detection unavailable\n' "$idx"
    fi
  fi
  if [ "$show_raw" -eq 1 ]; then
    printf 'RAW[%s]: BEGIN\n' "$idx"
    printf '%s\n' "$output"
    printf 'RAW[%s]: END\n' "$idx"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$idx" "$skill" "$expect" "$event" "$code" "$prompt" >> "$run_rows_file"
done

reliable=0
awk -F '\t' '$4 == "1" { found = 1 } END { exit(found ? 0 : 1) }' "$run_rows_file" && reliable=1

misses=0
printf 'INDEX\tSKILL\tEXPECT\tDETECTED\tRESULT\tEXIT\tPROMPT\n'
while IFS="$(printf '\t')" read -r idx skill expect event code prompt; do
  detected=unknown
  if [ "$code" -ne 0 ]; then
    detected=error
  elif [ "$event" = 1 ] || [ "$event" = 2 ]; then
    detected=trigger
  elif [ "$event" = 3 ]; then
    detected=no-trigger
  elif [ "$reliable" -eq 1 ]; then
    detected=no-trigger
  fi
  result=MISS
  if [ "$detected" = "$expect" ]; then result=PASS; else misses=$((misses + 1)); fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$idx" "$skill" "$expect" "$detected" "$result" "$code" "$prompt"
done < "$run_rows_file"

if [ "$reliable" -eq 0 ]; then
  printf 'NOT_VIABLE: no reliable Skill invocation event was observed in Claude Code stream-json output.\n'
fi
[ "$misses" -eq 0 ] || exit 1
exit 0
