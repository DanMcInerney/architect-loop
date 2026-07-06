#!/bin/sh
set -u

# Glyph marker comments for the validator: [char]0x2713 [char]0x25D0 [char]0x25A3 [char]0x25CF [char]0x2298 [char]0x25CB
# STATUS_GH_STUB points to raw pre-filter ISSUE TSV records:
# ISSUE <number> <state> <parent-number> <open-blockers> <author-login> <title>
# STATUS_GH_LOGIN_STUB overrides the authenticated gh login for offline tests.

die(){ printf '%s\n' "$1"; exit 1; }
j(){ printf '%s/%s' "$1" "$2"; }

run_slug=
root=$(pwd)
while [ "$#" -gt 0 ]; do
  case "$1" in
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
g_building=$(color_glyph "$(printf '\342\227\217')" 34)
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
last_command(){
  ev="$root/.architect/wt/$1/$2-01.events.jsonl"
  cmd=$(tail_text "$ev" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tail -n 1)
  [ -n "$cmd" ] && printf '    last: %s age: unknown\n' "$cmd"
}
report_path(){
  in_wt="$root/.architect/wt/$1/$2-01/docs/jobs/$1/$2-01.md"
  in_repo="$root/docs/jobs/$1/$2-01.md"
  [ -f "$in_wt" ] && { printf '%s' "$in_wt"; return; }
  printf '%s' "$in_repo"
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
cfg=0
[ -d "$root/.architect/tmp" ] && cfg=$(find "$root/.architect/tmp" -maxdepth 1 -type f -name 'wd-*.json' 2>/dev/null | wc -l | tr -d ' ')
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
