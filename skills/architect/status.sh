#!/bin/sh
set -u

# Glyph marker comments for the validator: [char]0x2713 [char]0x25D0 [char]0x25A3 [char]0x25C9 [char]0x2298 [char]0x25CB
# STATUS_GH_STUB points to raw pre-filter ISSUE TSV records:
# ISSUE <number> <state> <parent-number> <open-blockers> <author-login> <title>
# STATUS_GH_LOGIN_STUB overrides the authenticated gh login for offline tests.

die(){ printf '%s\n' "$1"; exit 1; }
j(){ printf '%s/%s' "$1" "$2"; }

run_slug=
root=$(pwd)
compact=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --compact)
      compact=true
      shift
      ;;
    --repo-root)
      [ "$#" -ge 2 ] || die 'missing value for --repo-root'
      root=$2
      shift 2
      ;;
    --repo-root=*)
      root=${1#--repo-root=}
      shift
      ;;
    -*)
      die "unknown argument: $1"
      ;;
    *)
      [ -z "$run_slug" ] || die "unexpected positional argument: $1"
      run_slug=$1
      shift
      ;;
  esac
done
case "$root" in /*) ;; *) root="$(pwd)/$root";; esac
[ -d "$root" ] || { printf 'unreadable repo: %s\n' "$root"; exit 1; }
case "$run_slug" in *[!A-Za-z0-9._-]* | '') [ -z "$run_slug" ] || die "invalid run slug: $run_slug";; esac

color_glyph(){
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    printf '\033[%sm%s\033[0m' "$2" "$1"
  else
    printf '%s' "$1"
  fi
}
g_merged=$(color_glyph "$(printf '\342\234\223')" 32)
g_judging=$(color_glyph "$(printf '\342\227\220')" 36)
g_blocked=$(color_glyph '!' 31)
g_reported=$(color_glyph "$(printf '\342\226\243')" 35)
g_building=$(color_glyph "$(printf '\342\227\211')" 34)
g_queued=$(color_glyph "$(printf '\342\212\230')" 33)
g_ready=$(color_glyph "$(printf '\342\227\213')" 37)

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
status_line(){ tail_text "$1" | sed 's/^\xEF\xBB\xBF//' | awk '/^STATUS:/{sub(/^STATUS:[[:space:]]*/,""); s=$0} END{print s}'; }
job_dir(){ printf '%s/.architect/jobs/%s/%s-01' "$root" "$1" "$2"; }
last_command_value(){
  for ev in "$root/.architect/jobs/$1/$2-01/events.jsonl" "$root/.architect/wt/$1/$2-01.events.jsonl"; do
    cmd=$(tail_text "$ev" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tail -n 1)
    [ -n "$cmd" ] && { printf '%s' "$cmd"; return; }
  done
}
last_command(){
  cmd=$(last_command_value "$1" "$2")
  [ -n "$cmd" ] && printf '    last: %s age: unknown\n' "$cmd"
}
report_path(){
  in_wt="$root/.architect/wt/$1/$2-01/docs/jobs/$1/$2-01.md"
  in_repo="$root/docs/jobs/$1/$2-01.md"
  [ -f "$in_wt" ] && { printf '%s' "$in_wt"; return; }
  printf '%s' "$in_repo"
}
json_field(){
  [ -f "$1" ] || return 0
  sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | tail -n 1
}
epoch_from_iso(){
  iso=$1
  [ -n "$iso" ] || return 1
  date -u -d "$iso" +%s 2>/dev/null && return 0
  clean=$(printf '%s' "$iso" | sed 's/\.[0-9][0-9]*Z$/Z/')
  date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$clean" +%s 2>/dev/null && return 0
  return 1
}
format_duration(){
  sec=$1
  case "$sec" in ''|*[!0-9]*) sec=0;; esac
  [ "$sec" -lt 0 ] && sec=0
  mins=$((sec / 60))
  if [ "$mins" -lt 1 ]; then printf '<1m'; return; fi
  if [ "$mins" -lt 60 ]; then printf '%sm' "$mins"; return; fi
  printf '%sh%02dm' $((mins / 60)) $((mins % 60))
}
job_runtime(){
  case "$3" in READY|QUEUED) return 0;; esac
  jd=$(job_dir "$1" "$2")
  start=$(json_field "$jd/job.meta.json" started_at)
  [ -n "$start" ] || return 0
  start_epoch=$(epoch_from_iso "$start") || return 0
  end=$(json_field "$jd/job.exit.json" ended_at)
  if [ -n "$end" ]; then end_epoch=$(epoch_from_iso "$end" || printf ''); else end_epoch=$(date -u +%s); fi
  case "$end_epoch" in ''|*[!0-9]*) end_epoch=$(date -u +%s);; esac
  format_duration $((end_epoch - start_epoch))
}
slugify(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//'; }
artifact_slugs(){
  [ -n "$1" ] || return 0
  [ -d "$root/.architect/wt/$1" ] || return 0
  find "$root/.architect/wt/$1" -maxdepth 1 -type d -name '*-01' 2>/dev/null | sed 's|.*/||;s/-01$//' | sort -u
}
phase(){
  rep=$(report_path "$1" "$2")
  if [ "${3:-}" = CLOSED ]; then printf '%s MERGED' "$g_merged"; return; fi
  if [ "${3:-}" = OPEN ] && [ -n "${4:-}" ]; then printf '%s QUEUED' "$g_queued"; return; fi
  judge=
  [ -d "$root/.architect/wt/$1" ] && judge=$(find "$root/.architect/wt/$1" -maxdepth 1 -type f -name "$2-01.judge*.md" 2>/dev/null | head -n 1)
  [ -f "$rep" ] && [ -n "$judge" ] && { printf '%s JUDGING' "$g_judging"; return; }
  st=$(status_line "$rep")
  case "$st" in BLOCKED*) printf '%s BLOCKED' "$g_blocked"; return;; esac
  [ -f "$rep" ] && { printf '%s REPORTED' "$g_reported"; return; }
  [ -d "$root/.architect/wt/$1/$2-01" ] && { printf '%s BUILDING' "$g_building"; return; }
  printf '%s READY' "$g_ready"
}
fm(){
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR==1 { sub(/^\357\273\277/,""); if ($0 != "---") exit 2 }
    NR>1 {
      if ($0 == "---") exit
      if (index($0, key ":") == 1) {
        sub(/^[^:]*:[[:space:]]*/, "")
        print
        exit
      }
    }
  ' "$1"
}
validate_manifest(){
  [ -f "$1" ] || return 1
  for key in run tracking-issue factory-branch tracker spec state created; do
    val=$(fm "$1" "$key")
    [ -n "$val" ] || die "manifest missing $key: $1"
  done
  track=$(fm "$1" tracking-issue)
  case "$track" in ''|*[!0-9]*) die "manifest tracking-issue is not an integer: $1";; esac
}
load_manifest(){
  selected_manifest=$1
  validate_manifest "$selected_manifest"
  selected_run=$(fm "$selected_manifest" run)
  selected_track=$(fm "$selected_manifest" tracking-issue)
  selected_tracker=$(fm "$selected_manifest" tracker)
  selected_spec=$(fm "$selected_manifest" spec)
  selected_state=$(fm "$selected_manifest" state)
  selected_lane=$(fm "$selected_manifest" lane)
  [ -n "$selected_lane" ] || selected_lane=architect
}
spec_name(){
  [ -n "${selected_spec:-}" ] && { basename "$selected_spec"; return; }
  newest_spec
}

manifest_missing=0
selected_manifest=
selected_run=
selected_track=
selected_tracker=
selected_spec=
selected_state=
selected_lane=architect
if [ -n "$run_slug" ]; then
  manifest="$root/docs/runs/$run_slug/manifest.md"
  if [ -f "$manifest" ]; then
    load_manifest "$manifest"
  else
    manifest_missing=1
    selected_run=$run_slug
  fi
else
  active_count=0
  active_lines=
  active_manifest=
  for manifest in "$root"/docs/runs/*/manifest.md; do
    [ -f "$manifest" ] || continue
    validate_manifest "$manifest"
    state=$(fm "$manifest" state)
    if [ "$state" = ACTIVE ]; then
      run=$(fm "$manifest" run)
      track=$(fm "$manifest" tracking-issue)
      active_count=$((active_count + 1))
      active_manifest=$manifest
      active_lines="${active_lines}RUN $run #$track $state
"
    fi
  done
  if [ "$active_count" -gt 1 ]; then
    printf '%s' "$active_lines"
    exit 0
  fi
  if [ "$active_count" -eq 1 ]; then
    load_manifest "$active_manifest"
  fi
fi

issue_meta_rows(){
  dir="$root/docs/issues/$selected_run"
  us=$(printf '\037')
  [ -d "$dir" ] || return 0
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    num=$(fm "$f" issue)
    title=$(fm "$f" title)
    state=$(fm "$f" state)
    parent=$(fm "$f" parent)
    blocked=$(fm "$f" blocked-by)
    case "$num" in ''|*[!0-9]*) continue;; esac
    [ -n "$title" ] && [ -n "$state" ] && [ -n "$parent" ] && [ -n "$blocked" ] || continue
    printf '%s%s%s%s%s%s%s%s%s\n' "$num" "$us" "$state" "$us" "$parent" "$us" "$blocked" "$us" "$title"
  done
}
markdown_lines(){
  rows=$(issue_meta_rows)
  us=$(printf '\037')
  printf '%s\n' "$rows" | awk -F "$us" -v track="$selected_track" '
    NF >= 5 {
      n++
      num[n] = $1
      state[n] = $2
      parent[n] = $3
      blocked[n] = $4
      title[n] = $5
      if ($2 == "OPEN") open[$1] = 1
      if ($1 == track) track_state = $2
    }
    END {
      if (track_state == "") exit 2
      if (track_state != "OPEN") { print "NOOPENRUN"; exit 0 }
      print "TRACK\t" track
      for (i = 1; i <= n; i++) {
        if (parent[i] != track) continue
        out = ""
        count = split(blocked[i], b, ",")
        for (j = 1; j <= count; j++) {
          gsub(/[[:space:]]/, "", b[j])
          if (b[j] in open) {
            if (out != "") out = out ","
            out = out b[j]
          }
        }
        print "SUB\t" num[i] "\t" state[i] "\t" out "\t" title[i]
      }
    }
  ' || { printf 'ERROR\tpinned issue #%s not present in docs/issues/%s\n' "$selected_track" "$selected_run"; return 1; }
}
expected_author(){
  [ -n "${STATUS_GH_LOGIN_STUB:-}" ] && { printf '%s' "$STATUS_GH_LOGIN_STUB"; return 0; }
  [ -n "${STATUS_EXPECTED_AUTHOR:-}" ] && { printf '%s' "$STATUS_EXPECTED_AUTHOR"; return 0; }
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status 2>&1 | awk '
    /Logged in to .* account / {
      for (i = 1; i <= NF; i++) {
        if ($i == "account") {
          print $(i + 1)
          exit
        }
      }
    }
  ' | sed 's/[()]//g'
}
raw_github_issue_lines(){
  if [ -n "${STATUS_GH_STUB:-}" ]; then
    [ -r "$STATUS_GH_STUB" ] || { printf 'ERROR\tSTATUS_GH_STUB not readable: %s\n' "$STATUS_GH_STUB"; return 1; }
    cat "$STATUS_GH_STUB"
    return 0
  fi
  command -v gh >/dev/null 2>&1 || { printf 'ERROR\tgh not found\n'; return 1; }
  raw_jq='.[] | ["ISSUE", (.number|tostring), .state, ((.parent.number // "")|tostring), ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), (.author.login // ""), .title] | @tsv'
  (cd "$root" && gh issue list --state all --limit 1000 --json number,title,state,parent,blockedBy,author --jq "$raw_jq") || {
    printf 'ERROR\tgh issue list failed\n'
    return 1
  }
}
github_lines(){
  expected=$(expected_author)
  [ -n "$expected" ] || { printf 'ERROR\tcould not resolve expected author login\n'; return 1; }
  raw=$(raw_github_issue_lines) || { printf '%s\n' "$raw"; return 1; }
  case "$raw" in ERROR*) printf '%s\n' "$raw"; return 1;; esac
  track_state=$(printf '%s\n' "$raw" | awk -F '	' -v track="$selected_track" '$1 == "ISSUE" && $2 == track { print $3; exit }')
  [ -n "$track_state" ] || { printf 'ERROR\tpinned issue #%s not present in github issue records\n' "$selected_track"; return 1; }
  [ "$track_state" = OPEN ] || { printf 'NOOPENRUN\n'; return 0; }
  printf 'TRACK\t%s\n' "$selected_track"
  printf '%s\n' "$raw" | awk -F '	' -v track="$selected_track" -v expected="$expected" '
    $1 == "ISSUE" && $4 == track && $6 == expected {
      print "SUB\t" $2 "\t" $3 "\t" $5 "\t" $7
    }
  ' | sort -n -k2
}
tracker_lines(){
  if [ "$manifest_missing" -eq 1 ]; then printf 'NOOPENRUN\n'; return 0; fi
  [ -n "$selected_manifest" ] || return 0
  case "$selected_tracker" in
    markdown) markdown_lines;;
    github) github_lines;;
    *) printf 'ERROR\tunknown tracker mode in manifest: %s\n' "$selected_tracker"; return 1;;
  esac
}
state_icon(){
  case "$1" in
    DONE) printf '%s' "$g_merged";;
    RUNNING) printf '%s' "$g_building";;
    JUDGING) printf '%s' "$g_judging";;
    BLOCKED) printf '%s' "$g_blocked";;
    QUEUED) printf '%s' "$g_queued";;
    *) printf '%s' "$g_ready";;
  esac
}
event_state(){
  f="$root/docs/runs/$selected_run/status-events.jsonl"
  [ -f "$f" ] || return 0
  sed -n '/"stage"[[:space:]]*:[[:space:]]*"'"$1"'"/s/.*"state"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | tail -n 1 | tr '[:upper:]' '[:lower:]'
}
stage_icon(){
  ev=$(event_state "$1")
  case "$ev" in
    complete|completed|done|skipped) printf '%s' "$g_merged";;
    running|started|in_progress|in-progress) printf '%s' "$g_building";;
    judging|reviewing) printf '%s' "$g_judging";;
    blocked) printf '%s' "$g_blocked";;
    *) state_icon "$2";;
  esac
}
stage_note(){
  f="$root/docs/runs/$selected_run/status-events.jsonl"
  note=
  if [ -f "$f" ]; then
    note=$(sed -n '/"stage"[[:space:]]*:[[:space:]]*"'"$1"'"/s/.*"note"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | tail -n 1)
  fi
  [ -n "$note" ] && printf '%s' "$note" || printf '%s' "$2"
}
clip_text(){
  awk -v s="$1" -v w="$2" 'BEGIN { if (length(s) <= w) print s; else print substr(s, 1, w - 1) "~" }'
}
node(){
  icon=$1
  label=$2
  note=$3
  last=${4:-}
  printf '                         %s %s\n' "$icon" "$label"
  [ -n "$note" ] && printf '          %s\n' "$(clip_text "$note" 72)"
  if [ "$last" != last ]; then
    printf '                           \342\224\202\n'
    printf '                           \342\226\274\n'
  fi
}
build_issue_rows(){
  if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
    printf '%s\n' "$tracker_tsv" | while IFS= read -r line; do
      kind=$(printf '%s\n' "$line" | awk -F '	' '{print $1}')
      [ "$kind" = SUB ] || continue
      num=$(printf '%s\n' "$line" | awk -F '	' '{print $2}')
      state=$(printf '%s\n' "$line" | awk -F '	' '{print $3}')
      blockers=$(printf '%s\n' "$line" | awk -F '	' '{print $4}')
      title=$(printf '%s\n' "$line" | awk -F '	' '{print $5}')
      slug=$(slugify "$title")
      set -- $(phase "$selected_run" "$slug" "$state" "$blockers")
      icon=$1
      phase_name=$2
      rt=$(job_runtime "$selected_run" "$slug" "$phase_name")
      case "$phase_name" in
        MERGED) detail=merged;;
        QUEUED) detail="blocked by #$blockers";;
        JUDGING) detail=check-runner;;
        BLOCKED) detail=blocked;;
        REPORTED) detail=reported;;
        BUILDING)
          last=$(last_command_value "$selected_run" "$slug")
          [ -n "$last" ] && detail="last: $(clip_text "$last" 28)" || detail=running
          ;;
        *) detail='not launched';;
      esac
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$icon" "$phase_name" "$num" "$title" "$rt" "$detail"
    done
  else
    for slug in $slugs; do
      set -- $(phase "$selected_run" "$slug")
      case "$2" in
        BUILDING|BLOCKED|JUDGING|REPORTED)
          rt=$(job_runtime "$selected_run" "$slug" "$2")
          printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "-" "$slug" "$rt" ".architect/wt/$selected_run/$slug-01"
          ;;
      esac
    done
  fi
}
builder_band(){
  rows=$1
  if [ -z "$rows" ]; then
    printf '     %s BUILDER ISSUES\n' "$g_ready"
    printf '       no builder issues published yet\n'
    return
  fi
  printf '%s\n' "$rows" | awk -F '	' -v w=24 '
    function clip(s) { return length(s) <= w ? s : substr(s, 1, w - 1) "~" }
    function pad(s,   c) { s = clip(s); c = w - length(s); while (c-- > 0) s = s " "; return s }
    NF >= 6 {
      line1 = line1 " " pad($1 " #" $3 " " $4)
      rt = $5 == "" ? "-" : $5
      line2 = line2 " " pad($2 " " rt)
      line3 = line3 " " pad($6)
      n++
      if (n % 5 == 0) {
        print substr(line1, 2); print substr(line2, 2); print substr(line3, 2); print ""
        line1 = line2 = line3 = ""
      }
    }
    END {
      if (line1 != "") { print substr(line1, 2); print substr(line2, 2); print substr(line3, 2) }
    }
  '
}
count_rows(){ printf '%s\n' "$1" | awk -F '	' 'NF >= 6 { n++ } END { print n + 0 }'; }
count_phase(){ printf '%s\n' "$1" | awk -F '	' -v p="$2" 'NF >= 6 && $2 == p { n++ } END { print n + 0 }'; }
count_started(){ printf '%s\n' "$1" | awk -F '	' 'NF >= 6 && $2 != "READY" && $2 != "QUEUED" { n++ } END { print n + 0 }'; }
compact_status(){
  printf 'STATUS TREE spec: %s branch: %s\n' "$(spec_name)" "$branch"
  if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
    printf 'tracker: #%s\n' "$tracking"
  elif [ "$tracker" -eq 1 ]; then
    printf 'tracker: no open run\n'
  else
    err=$(printf '%s' "$tracker_tsv" | sed 's/^ERROR	//;q')
    [ -n "$err" ] && printf 'tracker: unavailable (local view): %s\n' "$err" || printf 'tracker: unavailable (local view)\n'
  fi
  printf 'ORCHESTRATOR: local view\n'
  printf 'WATCHDOG: config=%s\n' "$cfg"
  if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
    printf '%s\n' "$tracker_tsv" | while IFS= read -r line; do
      kind=$(printf '%s\n' "$line" | awk -F '	' '{print $1}')
      [ "$kind" = SUB ] || continue
      num=$(printf '%s\n' "$line" | awk -F '	' '{print $2}')
      state=$(printf '%s\n' "$line" | awk -F '	' '{print $3}')
      blockers=$(printf '%s\n' "$line" | awk -F '	' '{print $4}')
      title=$(printf '%s\n' "$line" | awk -F '	' '{print $5}')
      slug=$(slugify "$title")
      set -- $(phase "$selected_run" "$slug" "$state" "$blockers")
      extra=
      [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"
      printf '%s #%s %s .architect/wt/%s/%s-01%s\n' "$1" "$num" "$title" "$selected_run" "$slug" "$extra"
      [ "$2" = BUILDING ] && last_command "$selected_run" "$slug"
    done
  else
    for slug in $slugs; do
      set -- $(phase "$selected_run" "$slug")
      case "$2" in
        BUILDING|BLOCKED|JUDGING|REPORTED)
          printf '%s %s .architect/wt/%s/%s-01\n' "$1" "$slug" "$selected_run" "$slug"
          [ "$2" = BUILDING ] && last_command "$selected_run" "$slug"
          ;;
      esac
    done
  fi
}
graph_status(){
  issue_rows_cache=$(build_issue_rows)
  total=$(count_rows "$issue_rows_cache")
  closed=$(count_phase "$issue_rows_cache" MERGED)
  running=$(count_phase "$issue_rows_cache" BUILDING)
  reported=$(count_phase "$issue_rows_cache" REPORTED)
  judging=$(count_phase "$issue_rows_cache" JUDGING)
  blocked=$(count_phase "$issue_rows_cache" BLOCKED)
  started=$(count_started "$issue_rows_cache")
  all_closed=false
  [ "$total" -gt 0 ] && [ "$closed" -eq "$total" ] && all_closed=true
  checks_exist=false
  [ -d "$root/docs/checks/$selected_run" ] && find "$root/docs/checks/$selected_run" -maxdepth 1 -type f -name '*.md' 2>/dev/null | grep -q . && checks_exist=true
  finish_state=WAITING
  [ "$selected_state" = FINISHED ] && finish_state=DONE
  tracker_text='tracker: unavailable (local view)'
  [ "$tracker" -eq 1 ] && tracker_text='tracker: no open run'
  [ -n "$tracking" ] && tracker_text="tracker: #$tracking"
  lane=$selected_lane
  [ "$lane" = fast ] && lane=architect-fast

  if [ "$lane" = architect-fast ]; then
    printf '/architect-fast\n'
    printf 'spec -> publish -> <=3 issues -> builders -> timed wake -> test pass -> builder review -> integrate -> PR\n\n'
  else
    printf '/architect\n'
    printf 'spec -> harden -> frozen checks -> wrapped builders -> typed gates -> test pass -> final review -> fix wave -> integrate -> PR\n\n'
  fi
  printf 'run: %s  spec: %s  branch: %s  %s\n\n' "$selected_run" "$(spec_name)" "$branch" "$tracker_text"

  if [ "$lane" = architect-fast ]; then
    spec_state=WAITING; [ -n "$selected_manifest" ] && spec_state=DONE
    publish_state=WAITING; [ -n "$tracking" ] && publish_state=DONE
    issue_state=WAITING; [ "$total" -gt 0 ] && issue_state=DONE; [ "$total" -eq 0 ] && [ -n "$tracking" ] && issue_state=RUNNING
    dispatch_state=WAITING; [ "$started" -gt 0 ] && dispatch_state=DONE
    builder_state=WAITING
    [ "$total" -gt 0 ] && builder_state=QUEUED
    [ $((running + reported + judging)) -gt 0 ] && builder_state=RUNNING
    [ "$blocked" -gt 0 ] && builder_state=BLOCKED
    [ "$all_closed" = true ] && builder_state=DONE
    node "$(stage_icon spec "$spec_state")" SPEC "$(stage_note spec 'orchestrator writes it; no question batch')"
    node "$(stage_icon publish "$publish_state")" PUBLISH "$(stage_note publish 'tracking issue + manifest; no approval gate')"
    node "$(stage_icon issues "$issue_state")" 'ISSUES (<=3)' "$(stage_note issues 'acceptance criteria; no frozen-check path')"
    node "$(stage_icon dispatch-head "$dispatch_state")" 'DISPATCH-HEAD SHA' "$(stage_note dispatch-head 'job diff base and postflight merge guard')"
    builder_band "$issue_rows_cache"
    printf '                           \342\224\202\n'
    printf '                           \342\226\274\n'
    wake_state=WAITING; [ $((running + reported + judging)) -gt 0 ] && wake_state=RUNNING
    review_state=WAITING; [ "$all_closed" = true ] && review_state=RUNNING
    node "$(stage_icon timed-wake "$wake_state")" 'TIMED FALLBACK WAKE' "$(stage_note timed-wake 'per wave; no watchdog script')"
    node "$(stage_icon closing-test "$review_state")" 'TEST PASS + BUILDER REVIEW' "$(stage_note closing-test 'orchestrator runs the suite; fresh builder reviews + fixes')"
    node "$(stage_icon integrate WAITING)" INTEGRATE "$(stage_note integrate 'docs pass, validation, PR or markdown finish')"
    node "$(stage_icon finish "$finish_state")" 'PR OR MARKDOWN FINISH RECORD' "$(stage_note finish 'ship digest and final handoff')" last
    return
  fi

  spec_state=WAITING; [ -n "$selected_manifest" ] && spec_state=DONE
  harden_state=WAITING; [ -n "$selected_manifest" ] && harden_state=RUNNING; { [ "$checks_exist" = true ] || [ "$total" -gt 0 ]; } && harden_state=DONE
  issue_check_state=WAITING
  { [ "$total" -gt 0 ] || [ "$checks_exist" = true ]; } && issue_check_state=RUNNING
  [ "$total" -gt 0 ] && [ "$checks_exist" = true ] && issue_check_state=DONE
  wrapper_state=WAITING; [ "$started" -gt 0 ] && wrapper_state=RUNNING; [ "$all_closed" = true ] && wrapper_state=DONE
  watchdog_state=WAITING; [ $((running + reported + judging)) -gt 0 ] && [ "$cfg" -gt 0 ] && watchdog_state=RUNNING; [ "$all_closed" = true ] && watchdog_state=DONE
  check_state=WAITING; [ $((judging + reported)) -gt 0 ] && check_state=JUDGING; [ "$all_closed" = true ] && check_state=DONE
  postflight_state=WAITING; { [ "$closed" -gt 0 ] || [ "$check_state" = JUDGING ]; } && postflight_state=RUNNING; [ "$all_closed" = true ] && postflight_state=DONE
  closing_state=WAITING; [ "$all_closed" = true ] && closing_state=RUNNING
  node "$(stage_icon spec "$spec_state")" SPEC "$(stage_note spec 'strategist draft; assumptions recorded')"
  node "$(stage_icon harden "$harden_state")" HARDEN "$(stage_note harden 'fresh strategist attacks, revises, decomposes')"
  node "$(stage_icon freeze "$issue_check_state")" 'ISSUES + FROZEN CHECKS' "$(stage_note freeze 'orchestrator publishes; checks frozen in git')"
  node "$(stage_icon wrapper "$wrapper_state")" 'PREFLIGHT + WRAPPER' "$(stage_note wrapper 'run-job owns heartbeat, exit truth, stderr, sandbox env')"
  builder_band "$issue_rows_cache"
  printf '                           \342\224\202\n'
  printf '                           \342\226\274\n'
  node "$(stage_icon watchdog "$watchdog_state")" 'WATCHDOG EVIDENCE' "$(stage_note watchdog "config=$cfg; detection only")"
  node "$(stage_icon check-runner "$check_state")" CHECK-RUNNER "$(stage_note check-runner 'graded RUN items; head/tail/pytest evidence')"
  node "$(stage_icon postflight "$postflight_state")" 'POSTFLIGHT + MERGE' "$(stage_note postflight 'touch-set audit; merge; cleanup or deferred cleanup')"
  node "$(stage_icon closing-test "$closing_state")" 'CLOSING TEST PASS' "$(stage_note closing-test 'builder-built suites plus every frozen RUN item')"
  node "$(stage_icon final-review WAITING)" 'FINAL REVIEW' "$(stage_note final-review 'read-only strategist fed the closing test pass; GREEN or FINDINGS')"
  node "$(stage_icon fix-wave WAITING)" 'FIX WAVE' "$(stage_note fix-wave 'FINDINGS become fix issues; GREEN skips this node')"
  node "$(stage_icon integrate WAITING)" INTEGRATE "$(stage_note integrate 'docs pass first; verify; sweep; PR handoff')"
  node "$(stage_icon finish "$finish_state")" 'PR OR MARKDOWN FINISH RECORD' "$(stage_note finish 'ship digest and final handoff')" last
}

branch=
[ -e "$root/.git" ] && branch=$(git -C "$root" branch --show-current 2>/dev/null || true)
[ -n "$branch" ] || branch=unknown
tracker=0
tracker_tsv=
if tracker_tsv=$(tracker_lines); then
  tracker=1
else
  tracker=0
fi
tracking=
if [ "$tracker" -eq 1 ]; then
  tracking=$(printf '%s\n' "$tracker_tsv" | awk -F '	' '$1 == "TRACK" { print $2; exit }')
fi
slugs=$(artifact_slugs "$selected_run")
if [ -z "$run_slug" ] && { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then
  printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"
  exit 0
fi
cfg=0
[ -d "$root/.architect/tmp" ] && cfg=$(find "$root/.architect/tmp" -maxdepth 1 -type f -name 'wd-*.json' 2>/dev/null | wc -l | tr -d ' ')
if [ "$compact" = true ]; then compact_status; else graph_status; fi
exit 0
