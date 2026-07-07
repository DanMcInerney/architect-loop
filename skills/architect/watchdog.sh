#!/usr/bin/env bash
set -u

cfg=
while [ "$#" -gt 0 ]; do
  case "$1" in -Config) cfg=$2; shift 2;; *) cfg=${cfg:-$1}; shift;; esac
done
[ -n "$cfg" ] || exit 1
[ -r "$cfg" ] || { printf 'WATCHDOG: ERROR missing config\n'; exit 5; }
json=$(tr -d '\r\n' < "$cfg")
sweep=$(printf '%s' "$json" | sed -n 's/.*"sweep_sec"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
stall=$(printf '%s' "$json" | sed -n 's/.*"stall_after_min"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
heartbeat_stale=$(printf '%s' "$json" | sed -n 's/.*"heartbeat_stale_sec"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
report_ready_grace=$(printf '%s' "$json" | sed -n 's/.*"report_ready_grace_sec"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
[ -n "$sweep" ] || sweep=120
[ -n "$stall" ] || stall=10
[ -n "$heartbeat_stale" ] || heartbeat_stale=$(awk -v s="$sweep" 'BEGIN{v=s*2; if(v<90)v=90; print v}')
[ -n "$report_ready_grace" ] || report_ready_grace=$sweep
jobs=$(printf '%s' "$json" | sed 's/.*"jobs"[[:space:]]*:[[:space:]]*\[//;s/\][^]]*$//;s/}[[:space:]]*,[[:space:]]*{/\}\n\{/g')

field(){ printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }
numfield(){ printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\([-0-9.]*\).*/\1/p"; }
fsize(){ stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || printf 0; }
mtime(){ stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || printf 0; }
now(){ date +%s; }
tail_text(){ [ -f "$1" ] && tail -c 4096 "$1" | tr -d '\000\377\376'; }
report_done(){ [ -f "$1" ] || return 1; last=$(tail_text "$1" | sed 's/^\xEF\xBB\xBF//' | awk 'NF{line=$0} END{gsub(/^[[:space:]]+|[[:space:]]+$/,"",line); print line}'); case "$last" in STATUS:*) return 0;; *) return 1;; esac; }
exit_code(){ [ -f "$1" ] && sed -n 's/.*"exit_code"[[:space:]]*:[[:space:]]*\([-0-9][0-9]*\).*/\1/p' "$1" | tail -n 1; }
state_field(){ [ -f "$1" ] && sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" "$1" | tail -n 1; }
save_state(){ printf '{"last_size":%s,"last_growth_epoch":%s,"last_evidence_epoch":%s,"report_ready_epoch":%s}\n' "$2" "$3" "$4" "$5" > "$1"; }
out_exit(){ code=$1; shift; printf '%s\n' "$1"; shift || true; for line in "$@"; do [ -n "${line:-}" ] && printf '%s\n' "$line"; done; exit "$code"; }
evidence_mtime(){ a=$(mtime "$1"); b=$(mtime "$2"); [ "$b" -gt "$a" ] && printf '%s' "$b" || printf '%s' "$a"; }

while :; do
  all=1
  done_lines=
  while IFS= read -r job; do
    [ -n "$job" ] || continue
    id=$(field "$job" id); events=$(field "$job" events_file); report=$(field "$job" report_path)
    worktree=$(field "$job" worktree); job_dir=$(field "$job" job_dir)
    [ -n "$job_dir" ] || job_dir=$(dirname "$events" 2>/dev/null)
    meta="$job_dir/job.meta.json"
    exit_file=$(field "$job" exit_file); [ -n "$exit_file" ] || exit_file="$job_dir/job.exit.json"
    heartbeat=$(field "$job" heartbeat_file); [ -n "$heartbeat" ] || heartbeat="$job_dir/job.heartbeat"
    state_file=$(field "$job" state_file); [ -n "$state_file" ] || state_file="$job_dir/job.state.json"
    terminal=false; report_done "$report" && terminal=true
    if [ -z "$job_dir" ] || [ ! -f "$meta" ]; then
      out_exit 10 "WATCHDOG: LEGACY_UNWRAPPED $id deterministic_exit=false terminal_status=$terminal"
    fi
    code=$(exit_code "$exit_file")
    integrated=false
    if [ -z "$code" ]; then
      if [ -n "$events" ] && [ ! -e "$events" ]; then integrated=true; fi
      if [ -n "$worktree" ] && [ ! -e "$worktree" ]; then integrated=true; fi
    fi
    if [ "$integrated" = true ]; then
      out_exit 2 "WATCHDOG: INTEGRATED $id"
    fi
    ev=$(fsize "$events"); rp=$(fsize "$report"); size=$((ev+rp)); n=$(now); ev_mtime=$(evidence_mtime "$events" "$report")
    last_size=$(state_field "$state_file" last_size); [ -n "$last_size" ] || last_size=$size
    last_growth=$(state_field "$state_file" last_growth_epoch); [ -n "$last_growth" ] || last_growth=$ev_mtime; [ "$last_growth" -gt 0 ] || last_growth=$n
    last_evidence=$(state_field "$state_file" last_evidence_epoch); [ -n "$last_evidence" ] || last_evidence=$ev_mtime
    report_ready=$(state_field "$state_file" report_ready_epoch); [ -n "$report_ready" ] || report_ready=0
    grew=false
    if [ "$size" != "$last_size" ] || [ "$ev_mtime" -gt "$last_evidence" ]; then last_size=$size; last_evidence=$ev_mtime; last_growth=$n; grew=true; fi
    if [ -n "$code" ]; then
      if [ "$code" = 0 ] && [ "$terminal" = true ]; then
        save_state "$state_file" "$last_size" "$last_growth" "$last_evidence" "$report_ready"
        done_lines="${done_lines}DONE_OK $id $report $(fsize "$report") bytes exit_code=0
"
        continue
      fi
      save_state "$state_file" "$last_size" "$last_growth" "$last_evidence" "$report_ready"
      out_exit 9 "WATCHDOG: DONE_FAILED $id exit_code=$code terminal_status=$terminal report=$report"
    fi
    all=0
    if [ "$terminal" = true ]; then
      if [ "$report_ready" = 0 ]; then report_ready=$n; save_state "$state_file" "$last_size" "$last_growth" "$last_evidence" "$report_ready"; continue; fi
      save_state "$state_file" "$last_size" "$last_growth" "$last_evidence" "$report_ready"
      age=$((n-report_ready))
      if awk -v a="$age" -v g="$report_ready_grace" 'BEGIN{exit !(a>=g)}'; then
        out_exit 6 "WATCHDOG: REPORT_READY $id terminal_status=true exit_file=false age_sec=$age"
      fi
      continue
    fi
    report_ready=0
    last4=$(tail_text "$events" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tail -n 4)
    if [ "$(printf '%s\n' "$last4" | sed '/^$/d' | wc -l | tr -d ' ')" = 4 ] && [ "$(printf '%s\n' "$last4" | sort -u | wc -l | tr -d ' ')" = 1 ]; then
      save_state "$state_file" "$last_size" "$last_growth" "$last_evidence" "$report_ready"
      out_exit 4 "WATCHDOG: REPEAT $id command=$(printf '%s\n' "$last4" | sed -n '1p') count=4"
    fi
    if [ -f "$heartbeat" ]; then hb_age=$((n-$(mtime "$heartbeat"))); elif [ -f "$meta" ]; then hb_age=$((n-$(mtime "$meta"))); else hb_age=999999; fi
    growth_age=$((n-last_growth))
    hint=$(numfield "$job" duration_hint_min); [ -n "$hint" ] || hint=0
    quiet=$(awk -v a="$stall" -v b="$hint" 'BEGIN{v=(a+b)*60; if(v<0)v=0; printf "%.0f", v}')
    save_state "$state_file" "$last_size" "$last_growth" "$last_evidence" "$report_ready"
    if awk -v h="$hb_age" -v s="$heartbeat_stale" 'BEGIN{exit !(h>s)}'; then
      recent=$(awk -v g="$growth_age" -v s="$sweep" 'BEGIN{exit !(g<=s+1)}'; printf $?)
      if [ "$grew" = true ] || [ "$recent" = 0 ]; then
        out_exit 7 "WATCHDOG: ORPHANED $id heartbeat_age_sec=$hb_age last_growth_age_sec=$growth_age"
      fi
      out_exit 8 "WATCHDOG: DEAD $id heartbeat_age_sec=$hb_age last_growth_age_sec=$growth_age"
    fi
    if awk -v g="$growth_age" -v q="$quiet" 'BEGIN{exit !(g>q)}'; then
      out_exit 3 "WATCHDOG: STALL $id seconds_since_growth=$growth_age heartbeat_age_sec=$hb_age" "$(tail_text "$events" | tail -n 5)"
    fi
  done <<EOF
$jobs
EOF
  if [ "$all" -eq 1 ]; then
    printf 'WATCHDOG: ALL_DONE\n'
    printf '%s' "$done_lines"
    exit 0
  fi
  sleep "$sweep"
done
