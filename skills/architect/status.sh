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
  spec_dir="$root/docs/spec"
  newest=
  newest_mtime=
  [ -d "$spec_dir" ] || { printf unknown; return; }
  for spec in "$spec_dir"/*.md; do
    [ -f "$spec" ] || continue
    mtime=$(stat -c %Y "$spec" 2>/dev/null || stat -f %m "$spec" 2>/dev/null || printf 0)
    case "$mtime" in ''|*[!0-9]*) mtime=0;; esac
    if [ -z "$newest" ] || [ "$mtime" -gt "$newest_mtime" ]; then
      newest=$spec
      newest_mtime=$mtime
    fi
  done
  [ -n "$newest" ] && basename "$newest" || printf unknown
}
tail_text(){ [ -f "$1" ] && tail -c 4096 "$1" | tr -d '\000'; }
status_line(){
  tail_text "$1" | sed 's/^\xEF\xBB\xBF//' | awk '/^STATUS:/{sub(/^STATUS:[[:space:]]*/,""); s=$0} END{print s}'
}
json_objects(){
  awk 'BEGIN{d=0;s=0;e=0;o=""}{for(i=1;i<=length($0);i++){c=substr($0,i,1);if(s){o=o c;if(e)e=0;else if(c=="\\")e=1;else if(c=="\"")s=0;continue}if(c=="\""){if(d>0)o=o c;s=1;continue}if(c=="{"){d++;o=o c;continue}if(d>0)o=o c;if(c=="}"){d--;if(d==0){print o;o=""}}}}'
}
issue_number(){ printf '%s' "$1" | grep -o '"number"[[:space:]]*:[[:space:]]*[0-9][0-9]*' | head -n 1 | sed 's/[^0-9]//g'; }
issue_title(){ printf '%s' "$1" | grep -o '"title"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"title"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'; }
issue_state(){ printf '%s' "$1" | grep -o '"state"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"state"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'; }
parent_number(){ printf '%s' "$1" | sed -n 's/.*"parent"[[:space:]]*:[[:space:]]*{[^}]*"number"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1; }
open_blockers(){
  block=$(printf '%s' "$1" | sed -n 's/.*"blockedBy"[[:space:]]*:[[:space:]]*\[\(.*\)\][[:space:]]*}.*/\1/p')
  [ -n "$block" ] || return
  printf '[%s]\n' "$block" | json_objects | while IFS= read -r blocker; do [ "$(issue_state "$blocker")" = OPEN ] && issue_number "$blocker"; done | paste -sd, -
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
tracker=0
if command -v gh >/dev/null 2>&1; then
  if gh_json=$(gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy 2>/dev/null); then
    tracker=1
  fi
fi
issue_objs=
tracking=
if [ "$tracker" -eq 1 ]; then
  issue_objs=$(printf '%s\n' "$gh_json" | json_objects)
  parent_refs=' '
  while IFS= read -r obj; do
    p=$(parent_number "$obj")
    [ -n "$p" ] && parent_refs="$parent_refs$p "
  done <<< "$issue_objs"
  highest=0
  while IFS= read -r obj; do
    num=$(issue_number "$obj")
    state=$(issue_state "$obj")
    [ -n "$num" ] || continue
    [ "$state" = OPEN ] || continue
    case "$parent_refs" in *" $num "*)
      if [ "$num" -gt "$highest" ]; then highest=$num; tracking=$num; fi
      ;;
    esac
  done <<< "$issue_objs"
fi
slugs=$(artifact_slugs)
if { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then
  printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"
  exit 0
fi
printf 'STATUS TREE spec: %s branch: %s\n' "$(newest_spec)" "$branch"
if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
  printf 'tracker: #%s\n' "$tracking"
elif [ "$tracker" -eq 1 ]; then
  printf 'tracker: no open run\n'
else
  printf 'tracker: unavailable (local view)\n'
fi
printf 'ORCHESTRATOR: local view\n'
cfg=$(find "$root/.architect/tmp" -maxdepth 1 -type f -name 'wd-*.json' 2>/dev/null | wc -l | tr -d ' ')
ps -eo args= 2>/dev/null | grep 'watchdog\.\(ps1\|sh\)' >/dev/null && proc=True || proc=False
printf 'WATCHDOG: process=%s config=%s\n' "$proc" "$cfg"
if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
  while IFS= read -r obj; do
    [ "$(parent_number "$obj")" = "$tracking" ] || continue
    num=$(issue_number "$obj")
    title=$(issue_title "$obj")
    state=$(issue_state "$obj")
    blockers=$(open_blockers "$obj")
    [ -n "$num" ] || continue
    slug=$(slugify "$title"); set -- $(phase "$slug" "$state" "$blockers")
    extra=; [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"
    printf '%s #%s %s .architect/wt/%s-01%s\n' "$1" "$num" "$title" "$slug" "$extra"
    [ "$2" = BUILDING ] && last_command "$slug"
  done <<< "$issue_objs"
else
  for slug in $slugs; do
    set -- $(phase "$slug")
    case "$2" in BUILDING|BLOCKED|JUDGING|REPORTED)
      printf '%s %s .architect/wt/%s-01\n' "$1" "$slug" "$slug"
      [ "$2" = BUILDING ] && last_command "$slug"
    esac
  done
fi
