#!/usr/bin/env bash
set -u

root=$(pwd)
while [ "$#" -gt 0 ]; do case "$1" in --repo-root) root=$2; shift 2;; *) shift;; esac; done
case "$root" in /*) ;; *) root="$(pwd)/$root";; esac
[ -d "$root" ] || { printf 'unreadable repo: %s\n' "$root"; exit 1; }

color_glyph(){ if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then printf '\033[%sm%s\033[0m' "$2" "$1"; else printf '%s' "$1"; fi; }
g_merged=$(color_glyph 'âœ“' 32); g_judging=$(color_glyph 'â—' 36); g_blocked=$(color_glyph '!' 31); g_reported=$(color_glyph 'â–£' 35); g_building=$(color_glyph 'â—' 34); g_queued=$(color_glyph 'âŠ˜' 33); g_ready=$(color_glyph 'â—‹' 37)
j(){ printf '%s/%s' "$1" "$2"; }
newest_spec(){ spec_dir="$root/docs/spec"; newest=; newest_mtime=; [ -d "$spec_dir" ] || { printf unknown; return; }; for spec in "$spec_dir"/*.md; do [ -f "$spec" ] || continue; mtime=$(stat -c %Y "$spec" 2>/dev/null || stat -f %m "$spec" 2>/dev/null || printf 0); case "$mtime" in ''|*[!0-9]*) mtime=0;; esac; if [ -z "$newest" ] || [ "$mtime" -gt "$newest_mtime" ]; then newest=$spec; newest_mtime=$mtime; fi; done; [ -n "$newest" ] && basename "$newest" || printf unknown; }
tail_text(){ [ -f "$1" ] && tail -c 4096 "$1" | tr -d '\000'; }
status_line(){ tail_text "$1" | sed 's/^\xEF\xBB\xBF//' | awk '/^STATUS:/{sub(/^STATUS:[[:space:]]*/,""); s=$0} END{print s}'; }
last_command(){ ev="$root/.architect/wt/$1-01.events.jsonl"; cmd=$(tail_text "$ev" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tail -n 1); [ -n "$cmd" ] && printf '    last: %s age: unknown\n' "$cmd"; }
report_path(){ in_wt="$root/.architect/wt/$1-01/docs/jobs/$1-01.md"; in_repo="$root/docs/jobs/$1-01.md"; [ -f "$in_wt" ] && { printf '%s' "$in_wt"; return; }; printf '%s' "$in_repo"; }
slugify(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//'; }
artifact_slugs(){ find "$root/.architect/wt" -maxdepth 1 -type d -name '*-01' 2>/dev/null | sed 's|.*/||;s/-01$//' | sort -u; }
phase(){ slug=$1; state=${2:-}; blockers=${3:-}; [ "$state" = CLOSED ] && { printf '%s MERGED' "$g_merged"; return; }; [ "$state" = OPEN ] && [ -n "$blockers" ] && { printf '%s QUEUED' "$g_queued"; return; }; rep=$(report_path "$slug"); judge=$(find "$root/.architect/wt" -maxdepth 1 -type f -name "$slug-01.judge*.md" 2>/dev/null | head -n 1); [ -f "$rep" ] && [ -n "$judge" ] && { printf '%s JUDGING' "$g_judging"; return; }; st=$(status_line "$rep"); case "$st" in BLOCKED*) printf '%s BLOCKED' "$g_blocked"; return;; esac; [ -f "$rep" ] && { printf '%s REPORTED' "$g_reported"; return; }; [ -d "$root/.architect/wt/$slug-01" ] && { printf '%s BUILDING' "$g_building"; return; }; printf '%s READY' "$g_ready"; }
tracker_mode(){ cfg="$root/.architect/config"; [ -f "$cfg" ] || { printf github; return; }; v=$(awk -F= '/^[[:space:]]*tracker[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2; exit}' "$cfg"); [ "$v" = markdown ] && printf markdown || printf github; }
fm(){ awk -v key="$2" 'NR==1{sub(/^\357\273\277/,""); if($0!="---") exit} NR>1{if($0=="---") exit; if(index($0,key":")==1){sub(/^[^:]*:[[:space:]]*/,""); print; exit}}' "$1"; }
has_num(){ [[ "$(printf '\n%s\n' "$1")" == *$'\n'"$2"$'\n'* ]]; }
trim_token(){ x=$1; x=${x//[[:space:]]/}; printf '%s' "$x"; }
markdown_lines(){
  dir="$root/docs/issues"; us=$(printf '\037'); rows=; parents=; open_nums=
  if [ -d "$dir" ]; then
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      num=$(fm "$f" issue); title=$(fm "$f" title); state=$(fm "$f" state); parent=$(fm "$f" parent); blocked=$(fm "$f" blocked-by)
      case "$num" in ''|*[!0-9]*) continue;; esac
      [ -n "$title" ] && [ -n "$state" ] && [ -n "$parent" ] && [ -n "$blocked" ] || continue
      rows="${rows}${num}${us}${state}${us}${parent}${us}${blocked}${us}${title}
"
      [ "$state" = OPEN ] && open_nums="${open_nums}${num}
"
      case "$parent" in *[!0-9]*|'') ;; *) parents="${parents}${parent}
";; esac
    done
  fi
  track=0
  while IFS="$(printf '\037')" read -r num state parent blocked title; do
    [ -n "$num" ] || continue
    if [ "$state" = OPEN ] && has_num "$parents" "$num" && [ "$num" -gt "$track" ]; then track=$num; fi
  done <<< "$rows"
  [ "$track" -eq 0 ] && { printf 'NOOPENRUN\n'; return 0; }
  printf 'TRACK\t%s\n' "$track"
  while IFS="$(printf '\037')" read -r num state parent blocked title; do
    [ "$parent" = "$track" ] || continue
    out=; oldifs=$IFS; IFS=,; set -- $blocked; IFS=$oldifs
    for b do b=$(trim_token "$b"); case "$b" in ''|*[!0-9]*) continue;; esac; has_num "$open_nums" "$b" && { [ -n "$out" ] && out="$out,$b" || out=$b; }; done
    printf 'SUB\t%s\t%s\t%s\t%s\n' "$num" "$state" "$out" "$title"
  done <<< "$rows"
}
tracker_lines(){
  if [ "$(tracker_mode)" = markdown ]; then markdown_lines; return 0; fi
  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
  if [ -n "${STATUS_GH_STUB:-}" ] && [ -r "$STATUS_GH_STUB" ]; then cat "$STATUS_GH_STUB"; return 0; fi
  command -v gh >/dev/null 2>&1 || return 1
  (cd "$root" && gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr")
}

branch=; [ -e "$root/.git" ] && branch=$(git -C "$root" branch --show-current 2>/dev/null || true); [ -n "$branch" ] || branch=unknown
tracker=0; tracker_tsv=; if tracker_tsv=$(tracker_lines 2>/dev/null); then tracker=1; fi
tracking=
if [ "$tracker" -eq 1 ]; then
  # Tab is whitespace to bash IFS: runs collapse and empty TSV fields shift later columns; translate to unit separators.
  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = TRACK ] && tracking=$num; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
fi
slugs=$(artifact_slugs)
if { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"; exit 0; fi
printf 'STATUS TREE spec: %s branch: %s\n' "$(newest_spec)" "$branch"
if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then printf 'tracker: #%s\n' "$tracking"; elif [ "$tracker" -eq 1 ]; then printf 'tracker: no open run\n'; else printf 'tracker: unavailable (local view)\n'; fi
printf 'ORCHESTRATOR: local view\n'
cfg=$(find "$root/.architect/tmp" -maxdepth 1 -type f -name 'wd-*.json' 2>/dev/null | wc -l | tr -d ' ')
ps -eo args= 2>/dev/null | grep 'watchdog\.\(ps1\|sh\)' >/dev/null && proc=True || proc=False
printf 'WATCHDOG: process=%s config=%s\n' "$proc" "$cfg"
if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = SUB ] || continue; slug=$(slugify "$title"); set -- $(phase "$slug" "$state" "$blockers"); extra=; [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"; printf '%s #%s %s .architect/wt/%s-01%s\n' "$1" "$num" "$title" "$slug" "$extra"; [ "$2" = BUILDING ] && last_command "$slug"; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
else
  for slug in $slugs; do set -- $(phase "$slug"); case "$2" in BUILDING|BLOCKED|JUDGING|REPORTED) printf '%s %s .architect/wt/%s-01\n' "$1" "$slug" "$slug"; [ "$2" = BUILDING ] && last_command "$slug";; esac; done
fi
