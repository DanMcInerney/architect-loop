#!/usr/bin/env bash
set -u

root=$(pwd)
while [ "$#" -gt 0 ]; do
  case "$1" in --repo-root) root=$2; shift 2;; *) shift;; esac
done
case "$root" in /*) ;; *) root="$(pwd)/$root";; esac
[ -d "$root" ] || { printf 'unreadable repo: %s\n' "$root"; exit 1; }

g_merged='✓'; g_judging='◐'; g_blocked='!'; g_reported='▣'; g_building='●'; g_queued='⊘'; g_ready='○'
j(){ printf '%s/%s' "$1" "$2"; }
newest_spec(){
  spec=$(find "$root/docs/spec" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | tail -n 1)
  [ -n "$spec" ] && basename "$spec" || printf unknown
}
tail_text(){ [ -f "$1" ] && tail -c 4096 "$1" | tr -d '\000'; }
status_line(){
  tail_text "$1" | sed 's/^\xEF\xBB\xBF//' | awk '/^STATUS:/{sub(/^STATUS:[[:space:]]*/,""); s=$0} END{print s}'
}
last_command(){
  ev="$root/.architect/wt/$1-01.events.jsonl"
  cmd=$(tail_text "$ev" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tail -n 1)
  [ -n "$cmd" ] && printf '    last: %s age: unknown\n' "$cmd"
}
report_path(){
  in_wt="$root/.architect/wt/$1-01/docs/jobs/$1-01.md"
  in_repo="$root/docs/jobs/$1-01.md"
  [ -f "$in_wt" ] && { printf '%s' "$in_wt"; return; }
  printf '%s' "$in_repo"
}
slugify(){
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//'
}
artifact_slugs(){
  {
    find "$root/.architect/wt" -maxdepth 1 -type d -name '*-01' 2>/dev/null | sed 's|.*/||;s/-01$//'
    find "$root/.architect/wt" -maxdepth 1 -type f -name '*-01.events.jsonl' 2>/dev/null | sed 's|.*/||;s/-01\.events\.jsonl$//'
    find "$root/.architect/wt" -maxdepth 1 -type f -name '*-01.judge*.md' 2>/dev/null | sed 's|.*/||;s/-01\.judge.*$//'
    find "$root/.architect/wt" -path '*/docs/jobs/*-01.md' -type f 2>/dev/null | sed 's|.*/docs/jobs/||;s/-01\.md$//'
    find "$root/docs/jobs" -maxdepth 1 -type f -name '*-01.md' 2>/dev/null | sed 's|.*/||;s/-01\.md$//'
  } | sort -u
}
phase(){
  slug=$1; state=${2:-}; blockers=${3:-}
  [ "$state" = CLOSED ] && { printf '%s MERGED' "$g_merged"; return; }
  rep=$(report_path "$slug")
  judge=$(find "$root/.architect/wt" -maxdepth 1 -type f -name "$slug-01.judge*.md" 2>/dev/null | head -n 1)
  [ -f "$rep" ] && [ -n "$judge" ] && { printf '%s JUDGING' "$g_judging"; return; }
  st=$(status_line "$rep")
  case "$st" in BLOCKED*) printf '%s BLOCKED' "$g_blocked"; return;; esac
  [ -f "$rep" ] && { printf '%s REPORTED' "$g_reported"; return; }
  [ -d "$root/.architect/wt/$slug-01" ] && { printf '%s BUILDING' "$g_building"; return; }
  [ -n "$blockers" ] && { printf '%s QUEUED' "$g_queued"; return; }
  printf '%s READY' "$g_ready"
}

branch=
[ -e "$root/.git" ] && branch=$(git -C "$root" branch --show-current 2>/dev/null || true)
[ -n "$branch" ] || branch=unknown
gh_json=
if command -v gh >/dev/null 2>&1; then gh_json=$(gh issue list --json number,title,state,parent,blockedBy,assignees 2>/dev/null || true); fi
tracker=0
[ -n "$gh_json" ] && tracker=1
slugs=$(artifact_slugs)
if [ "$tracker" -eq 0 ] && [ -z "$slugs" ]; then
  printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"
  exit 0
fi
printf 'STATUS TREE spec: %s branch: %s\n' "$(newest_spec)" "$branch"
[ "$tracker" -eq 1 ] && printf 'tracker: available\n' || printf 'tracker: unavailable (local view)\n'
printf 'ORCHESTRATOR: local view\n'
cfg=$(find "$root/.architect/tmp" -maxdepth 1 -type f -name 'wd-*.json' 2>/dev/null | wc -l | tr -d ' ')
ps -eo args= 2>/dev/null | grep 'watchdog\.\(ps1\|sh\)' >/dev/null && proc=True || proc=False
printf 'WATCHDOG: process=%s config=%s\n' "$proc" "$cfg"
if [ "$tracker" -eq 1 ]; then
  printf '%s\n' "$gh_json" | sed 's/^\[//;s/\]$//;s/},{/}\
{/g' | while IFS= read -r obj; do
    num=$(printf '%s' "$obj" | sed -n 's/.*"number":[[:space:]]*\([0-9][0-9]*\).*/\1/p')
    title=$(printf '%s' "$obj" | sed -n 's/.*"title":[[:space:]]*"\([^"]*\)".*/\1/p')
    state=$(printf '%s' "$obj" | sed -n 's/.*"state":[[:space:]]*"\([^"]*\)".*/\1/p')
    blockers=$(printf '%s' "$obj" | grep -o '"blockedBy":[^]]*' | grep -o '"number":[0-9]*' | sed 's/[^0-9]//g' | paste -sd, -)
    [ -n "$num" ] || continue
    slug=$(slugify "$title"); set -- $(phase "$slug" "$state" "$blockers")
    extra=; [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"
    printf '%s #%s %s .architect/wt/%s-01%s\n' "$1" "$num" "$title" "$slug" "$extra"
    [ "$2" = BUILDING ] && last_command "$slug"
  done
else
  for slug in $slugs; do
    set -- $(phase "$slug")
    case "$2" in BUILDING|BLOCKED|JUDGING|REPORTED)
      printf '%s %s .architect/wt/%s-01\n' "$1" "$slug" "$slug"
      [ "$2" = BUILDING ] && last_command "$slug"
    esac
  done
fi
