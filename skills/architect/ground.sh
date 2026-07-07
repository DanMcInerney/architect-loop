#!/bin/sh
set -u

# Ground reconcile + stop/environment gates + ready-frontier computation.
# Detection only: no writes, no tracker posts, no merges.
# Output contract (greppable):
#   ISSUE: <n> <open|closed> blockedBy=<comma-list|none>
#   BRANCH: <name> <local-sha|missing> <synced|ahead=N behind=N|unknown>
#   UNGRADED: <slug>                          (report without matching checkrun)
#   FRONTIER: <n> <n>...                      (always emitted, possibly empty)
# Typed exit + summary line, always last:
#   0 GROUND: OK issues=<closed>/<total> frontier=<k> freeze=<short-sha>
#   2 GROUND: STOP <which>
#   3 GROUND: DRIFT <fact>
#   5 GROUND: ERROR <why>

die5(){ printf 'GROUND: ERROR %s\n' "$1"; exit 5; }

run_slug=
root=$(pwd)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-root)
      [ "$#" -ge 2 ] || die5 'missing value for --repo-root'
      root=$2
      shift 2
      ;;
    --repo-root=*)
      root=${1#--repo-root=}
      shift
      ;;
    -*)
      die5 "unknown argument: $1"
      ;;
    *)
      [ -z "$run_slug" ] || die5 "unexpected positional argument: $1"
      run_slug=$1
      shift
      ;;
  esac
done
[ -n "$run_slug" ] || die5 'missing run argument'
case "$root" in /*|[A-Za-z]:*) ;; *) root="$(pwd)/$root";; esac
[ -d "$root" ] || die5 "unreadable repo: $root"
case "$run_slug" in *[!A-Za-z0-9._-]*) die5 "invalid run slug: $run_slug";; esac

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

manifest="$root/docs/runs/$run_slug/manifest.md"
[ -f "$manifest" ] || die5 "missing manifest: $manifest"
for key in run tracking-issue factory-branch tracker spec state; do
  val=$(fm "$manifest" "$key")
  [ -n "$val" ] || die5 "manifest missing $key: $manifest"
done
m_track=$(fm "$manifest" tracking-issue)
m_branch=$(fm "$manifest" factory-branch)
m_tracker=$(fm "$manifest" tracker)
m_state=$(fm "$manifest" state)
case "$m_track" in ''|*[!0-9]*) die5 "manifest tracking-issue is not an integer: $manifest";; esac
case "$m_tracker" in github|markdown) ;; *) die5 "unknown tracker mode in manifest: $m_tracker";; esac

# --- Gates: docs/STOP (run + primary checkout), per-run STOP, subagent-model env ---
stop_which=
[ -f "$root/docs/STOP" ] && stop_which=run-checkout
if [ -z "$stop_which" ]; then
  gcd=$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)
  if [ -n "$gcd" ]; then
    case "$gcd" in /*|[A-Za-z]:*) ;; *) gcd="$root/$gcd";; esac
    primary_root=$(dirname "$gcd")
    [ -f "$primary_root/docs/STOP" ] && stop_which=primary-checkout
  fi
fi
[ -z "$stop_which" ] && [ -f "$root/docs/runs/$run_slug/STOP" ] && stop_which=run-stop
[ -z "$stop_which" ] && [ -n "${CLAUDE_CODE_SUBAGENT_MODEL:-}" ] && stop_which=subagent-model-env
if [ -n "$stop_which" ]; then
  printf 'GROUND: STOP %s\n' "$stop_which"
  exit 2
fi

# --- Tracker reconcile: github via gh scoped by run marker, markdown via docs/issues/<run>/ ---
track_state=
track_body=
children_tsv=

if [ "$m_tracker" = github ]; then
  command -v gh >/dev/null 2>&1 || die5 "gh not found"
  track_json=$( (cd "$root" && gh issue view "$m_track" --json state,body --jq '[.state, .body] | @tsv') 2>&1) || die5 "gh issue view failed: $track_json"
  track_state=$(printf '%s' "$track_json" | awk -F '\t' '{print $1}')
  track_body=$(printf '%s\n' "$track_json" | cut -f2-)
  jq_filter='[.[] | select(.parent.number == '"$m_track"') | select((.body // "") | contains("<!-- architect-run: '"$run_slug"' -->"))] | .[] | [(.number|tostring), .state, ((.blockedBy.nodes // []) | map((.number|tostring)) | join(",")), ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title] | @tsv'
  children_tsv=$( (cd "$root" && gh issue list --state all --limit 1000 --json number,title,state,parent,blockedBy,body --jq "$jq_filter") 2>&1) || die5 "gh issue list failed: $children_tsv"
else
  dir="$root/docs/issues/$run_slug"
  rows=
  if [ -d "$dir" ]; then
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      num=$(fm "$f" issue)
      title=$(fm "$f" title)
      state=$(fm "$f" state)
      parent=$(fm "$f" parent)
      blocked=$(fm "$f" blocked-by)
      case "$num" in ''|*[!0-9]*) continue;; esac
      [ -n "$title" ] && [ -n "$state" ] && [ -n "$parent" ] || continue
      rows="${rows}${num}	${state}	${parent}	${blocked}	${title}
"
    done
  fi
  md_out=$(printf '%s' "$rows" | awk -F '\t' -v track="$m_track" '
    NF >= 5 {
      n = $1
      st[n] = $2
      par[n] = $3
      blk[n] = $4
      ttl[n] = $5
      rows[++count] = n
    }
    END {
      if (!(track in st)) { print "ERROR\tpinned issue #" track " not present in docs/issues"; exit }
      print "TRACKSTATE\t" st[track]
      for (i = 1; i <= count; i++) {
        n = rows[i]
        if (par[n] != track) continue
        c = split(blk[n], parts, ",")
        all = ""; openb = ""
        for (j = 1; j <= c; j++) {
          gsub(/[ \t]/, "", parts[j])
          if (parts[j] == "" || parts[j] == "none") continue
          if (all == "") all = parts[j]; else all = all "," parts[j]
          if ((parts[j] in st) && st[parts[j]] == "OPEN") {
            if (openb == "") openb = parts[j]; else openb = openb "," parts[j]
          }
        }
        print "CHILD\t" n "\t" st[n] "\t" all "\t" openb "\t" ttl[n]
      }
    }
  ')
  case "$md_out" in
    ERROR*) die5 "$(printf '%s' "$md_out" | cut -f2-)";;
  esac
  track_state=$(printf '%s\n' "$md_out" | awk -F '\t' '$1 == "TRACKSTATE" { print $2; exit }')
  children_tsv=$(printf '%s\n' "$md_out" | awk -F '\t' '$1 == "CHILD" { print $2"\t"$3"\t"$4"\t"$5"\t"$6 }')
  if [ -d "$dir" ]; then
    for cand in "$dir"/*.md; do
      [ -f "$cand" ] || continue
      if [ "$(fm "$cand" issue)" = "$m_track" ]; then
        track_body=$(awk '
          NR == 1 && $0 == "---" { infm = 1; next }
          infm && $0 == "---" { infm = 0; next }
          !infm { print }
        ' "$cand")
      fi
    done
  fi
fi

drift_reason=

# --- Tracker/git disagreement: manifest state vs tracking-issue tracker state ---
if [ "$m_state" = "ACTIVE" ] && [ "$track_state" = "CLOSED" ]; then
  drift_reason="manifest state ACTIVE but tracking issue #$m_track is CLOSED"
elif [ "$m_state" = "FINISHED" ] && [ "$track_state" = "OPEN" ]; then
  drift_reason="manifest state FINISHED but tracking issue #$m_track is OPEN"
fi

# --- Emit ISSUE lines: tracking issue + reconciled children ---
track_lower=open
[ "$track_state" = "CLOSED" ] && track_lower=closed
printf 'ISSUE: %s %s blockedBy=none\n' "$m_track" "$track_lower"

children_tsv=$(printf '%s\n' "$children_tsv" | sort -t "$(printf '\t')" -k1,1n 2>/dev/null)

total=0
closed_count=0
frontier_nums=
while IFS= read -r line || [ -n "$line" ]; do
  [ -n "$line" ] || continue
  num=$(printf '%s' "$line" | awk -F '\t' '{print $1}')
  st=$(printf '%s' "$line" | awk -F '\t' '{print $2}')
  allb=$(printf '%s' "$line" | awk -F '\t' '{print $3}')
  openb=$(printf '%s' "$line" | awk -F '\t' '{print $4}')
  [ -n "$num" ] || continue
  total=$((total + 1))
  lower=open
  if [ "$st" = "CLOSED" ]; then lower=closed; closed_count=$((closed_count + 1)); fi
  blist=$allb
  [ -n "$blist" ] || blist=none
  printf 'ISSUE: %s %s blockedBy=%s\n' "$num" "$lower" "$blist"
  if [ "$st" = "OPEN" ] && [ -z "$openb" ]; then
    frontier_nums="${frontier_nums:+$frontier_nums }$num"
  fi
done <<EOF
$children_tsv
EOF

# --- Freeze: recorded on tracking-issue body, else latest docs/checks/<run>/ commit ---
freeze_sha=$(printf '%s\n' "$track_body" | grep -io 'freeze[^0-9a-zA-Z]*[0-9a-f]\{7,40\}' 2>/dev/null | grep -oE '[0-9a-f]{7,40}$' 2>/dev/null | head -n 1)
if [ -z "$freeze_sha" ]; then
  freeze_sha=$(git -C "$root" log -1 --format=%H -- "docs/checks/$run_slug/" 2>/dev/null)
fi
if [ -z "$freeze_sha" ]; then
  [ -n "$drift_reason" ] || drift_reason="no freeze commit recorded for docs/checks/$run_slug/"
elif ! git -C "$root" cat-file -e "$freeze_sha^{commit}" >/dev/null 2>&1; then
  [ -n "$drift_reason" ] || drift_reason="recorded freeze $freeze_sha not resolvable to a commit"
  freeze_sha=
else
  freeze_diff=$(git -C "$root" diff --stat "$freeze_sha"..HEAD -- "docs/checks/$run_slug/" 2>&1)
  if [ -n "$freeze_diff" ]; then
    [ -n "$drift_reason" ] || drift_reason="docs/checks/$run_slug/ changed since freeze $freeze_sha"
  fi
fi

# --- Branches: factory-branch head vs origin ---
local_sha=$(git -C "$root" rev-parse --verify -q "refs/heads/$m_branch" 2>/dev/null)
origin_line=$(git -C "$root" ls-remote origin "refs/heads/$m_branch" 2>/dev/null)
origin_sha=$(printf '%s' "$origin_line" | awk '{print $1}')
if [ -z "$local_sha" ]; then
  printf 'BRANCH: %s missing\n' "$m_branch"
else
  branch_status=unknown
  if [ -n "$origin_sha" ] && [ "$local_sha" = "$origin_sha" ]; then
    branch_status=synced
  elif [ -n "$origin_sha" ] && git -C "$root" cat-file -e "$origin_sha^{commit}" >/dev/null 2>&1; then
    counts=$(git -C "$root" rev-list --left-right --count "$local_sha...$origin_sha" 2>/dev/null)
    ahead=$(printf '%s' "$counts" | awk '{print $1}')
    behind=$(printf '%s' "$counts" | awk '{print $2}')
    [ -n "$ahead" ] && [ -n "$behind" ] && branch_status="ahead=$ahead behind=$behind"
  fi
  printf 'BRANCH: %s %s %s\n' "$m_branch" "$local_sha" "$branch_status"
fi

# --- Ungraded: docs/jobs/<run>/<issue-slug>-NN.md lacking <issue-slug>-checkrun.md ---
# Reports carry a trailing job number (-01, -02, ...); checkrun evidence is
# per issue slug without it (dispatch.md: docs/jobs/<run>/<issue-slug>-checkrun.md),
# so strip the trailing -NN before matching (s1-ground ruling 2026-07-06).
ungraded_found=0
jobs_dir="$root/docs/jobs/$run_slug"
if [ -d "$jobs_dir" ]; then
  for f in "$jobs_dir"/*-[0-9][0-9].md; do
    [ -f "$f" ] || continue
    base=$(basename "$f" .md)
    slug=$(printf '%s' "$base" | sed 's/-[0-9][0-9]$//')
    checkrun="$jobs_dir/${slug}-checkrun.md"
    if [ ! -f "$checkrun" ]; then
      rulings="$jobs_dir/${slug}-rulings.md"
      if [ -f "$rulings" ] && grep -q '^GRADED-BY-RULING:' "$rulings"; then
        printf 'GRADED: %s graded_by_ruling=%s\n' "$slug" "$slug"
        continue
      fi
      printf 'UNGRADED: %s\n' "$slug"
      ungraded_found=1
    fi
  done
fi
if [ "$ungraded_found" -eq 1 ]; then
  [ -n "$drift_reason" ] || drift_reason="ungraded job report(s) present without checkrun evidence"
fi

if [ -n "$drift_reason" ]; then
  printf 'GROUND: DRIFT %s\n' "$drift_reason"
  exit 3
fi

# --- Frontier: open issues whose blockedBy are all closed ---
if [ -n "$frontier_nums" ]; then
  frontier_nums=$(printf '%s\n' "$frontier_nums" | tr ' ' '\n' | sort -n | tr '\n' ' ' | sed 's/[[:space:]]*$//')
fi
printf 'FRONTIER:%s\n' "${frontier_nums:+ $frontier_nums}"
frontier_count=0
[ -n "$frontier_nums" ] && frontier_count=$(printf '%s\n' "$frontier_nums" | wc -w | tr -d ' ')
freeze_short=$(git -C "$root" rev-parse --short "$freeze_sha" 2>/dev/null)
printf 'GROUND: OK issues=%s/%s frontier=%s freeze=%s\n' "$closed_count" "$total" "$frontier_count" "$freeze_short"
exit 0
