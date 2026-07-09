#!/usr/bin/env bash
set -u

cfg=${1:-}
[ -n "$cfg" ] && [ -r "$cfg" ] || { printf 'WATCHDOG: ERROR unreadable config\n'; exit 5; }

json=$(tr -d '\r\n' < "$cfg")
sweep=$(printf '%s' "$json" | sed -n 's/.*"sweep_sec"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
stall=$(printf '%s' "$json" | sed -n 's/.*"stall_after_min"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
heartbeat_stale=$(printf '%s' "$json" | sed -n 's/.*"heartbeat_stale_sec"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
report_ready_grace=$(printf '%s' "$json" | sed -n 's/.*"report_ready_grace_sec"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
jobs=$(printf '%s' "$json" | sed 's/.*"jobs"[[:space:]]*:[[:space:]]*\[//;s/\][^]]*$//;s/}[[:space:]]*,[[:space:]]*{/\}\n\{/g')
[ -n "$sweep" ] || sweep=120
[ -n "$stall" ] || stall=10
[ -n "$heartbeat_stale" ] || heartbeat_stale=$(awk -v s="$sweep" 'BEGIN{v=s*2; if(v<90)v=90; print v}')
[ -n "$report_ready_grace" ] || report_ready_grace=$sweep

field() { printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }
numfield() { printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p"; }
fsize() { stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || printf 0; }
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || printf 0; }
now() { date +%s; }
age_sec() {
  local path="${1:-}"
  local modified=0
  [ -n "$path" ] && [ -e "$path" ] && modified=$(mtime "$path")
  [ "$modified" -gt 0 ] || { printf 999999; return 0; }
  printf '%s' $(( $(now) - modified ))
}
tail_text() { [ -f "$1" ] && tail -c 4096 "$1" | tr -d '\000\377\376'; }
report_done() {
  [ -f "$1" ] || return 1
  last=$(tail_text "$1" | awk 'NF{line=$0} END{gsub(/^[[:space:]]+|[[:space:]]+$/,"",line); print line}')
  case "$last" in STATUS:*) return 0;; *) return 1;; esac
}
exit_code() {
  [ -f "$1" ] || return 0
  sed -n 's/.*"exit_code"[[:space:]]*:[[:space:]]*\([-0-9][0-9]*\).*/\1/p' "$1" | tail -n 1
}
cpu_sum() {
  needle=$1
  if [ -d /proc ]; then
    total=0
    for p in /proc/[0-9]*; do
      [ -r "$p/cmdline" ] || continue
      cmd=$(tr '\000' ' ' < "$p/cmdline")
      case "$cmd" in *"$needle"*) v=$(awk '{print $14+$15}' "$p/stat" 2>/dev/null); total=$((total+${v:-0}));; esac
    done
    printf '%s' "$total"
  else
    ps -eo time= -o args= 2>/dev/null | awk -v w="$needle" 'index($0,w){split($1,d,"-"); t=(length(d)==2?d[2]:$1); split(t,c,":"); if(length(c)==3)s+=c[1]*3600+c[2]*60+c[3]; else if(length(c)==2)s+=c[1]*60+c[2]} END{print s+0}'
  fi
}

ids=()
events=()
reports=()
job_dirs=()
exit_files=()
heartbeat_files=()
stderr_files=()
trees=()
hints=()
done_flags=()
report_ready_since=()
sizes=()
growth=()
cpus=()

i=0
while IFS= read -r job || [ -n "$job" ]; do
  [ -n "$job" ] || continue
  ids[$i]=$(field "$job" id)
  events[$i]=$(field "$job" events_file)
  reports[$i]=$(field "$job" report_path)
  job_dirs[$i]=$(field "$job" job_dir)
  exit_files[$i]=$(field "$job" exit_file)
  heartbeat_files[$i]=$(field "$job" heartbeat_file)
  stderr_files[$i]=$(field "$job" stderr_file)
  if [ -z "${exit_files[$i]}" ] && [ -n "${job_dirs[$i]}" ]; then
    exit_files[$i]="${job_dirs[$i]}/job.exit.json"
  fi
  if [ -z "${heartbeat_files[$i]}" ] && [ -n "${job_dirs[$i]}" ]; then
    heartbeat_files[$i]="${job_dirs[$i]}/job.heartbeat"
  fi
  if [ -z "${stderr_files[$i]}" ] && [ -n "${job_dirs[$i]}" ]; then
    stderr_files[$i]="${job_dirs[$i]}/stderr.log"
  fi
  trees[$i]=$(field "$job" worktree)
  hints[$i]=$(numfield "$job" duration_hint_min)
  [ -n "${hints[$i]}" ] || hints[$i]=0
  done_flags[$i]=0
  report_ready_since[$i]=0
  ev=$(fsize "${events[$i]}")
  rp=$(fsize "${reports[$i]}")
  er=$(fsize "${stderr_files[$i]}")
  sizes[$i]=$((ev + rp + er))
  growth[$i]=$(now)
  cpus[$i]=$(cpu_sum "${trees[$i]}")
  i=$((i + 1))
done <<EOF
$jobs
EOF

[ "${#ids[@]}" -gt 0 ] || { printf 'WATCHDOG: ERROR no jobs\n'; exit 5; }

while :; do
  all_done=1
  for i in "${!ids[@]}"; do
    [ "${done_flags[$i]}" = 1 ] && continue
    code=
    if [ -n "${exit_files[$i]}" ]; then
      code=$(exit_code "${exit_files[$i]}")
    fi
    if [ -n "$code" ]; then
      if [ "$code" = 0 ] && report_done "${reports[$i]}"; then
        done_flags[$i]=1
        continue
      fi
      if [ "$code" != 0 ]; then
        printf 'WATCHDOG: DONE_FAILED %s exit_code=%s report=%s\n' "${ids[$i]}" "$code" "${reports[$i]}"
        exit 9
      fi
    elif [ -n "${job_dirs[$i]}" ] && report_done "${reports[$i]}"; then
      now_epoch=$(now)
      if [ "${report_ready_since[$i]}" = 0 ]; then
        report_ready_since[$i]=$now_epoch
      fi
      ready_age=$((now_epoch - report_ready_since[$i]))
      hb_age=$(age_sec "${heartbeat_files[$i]}")
      if awk -v h="$hb_age" -v s="$heartbeat_stale" -v r="$ready_age" -v g="$report_ready_grace" 'BEGIN{exit !(h>s && r>=g)}'; then
        printf 'WATCHDOG: REPORT_READY %s terminal_status=true exit_file=false heartbeat_age_sec=%s report_ready_age_sec=%s\n' "${ids[$i]}" "$hb_age" "$ready_age"
        exit 6
      fi
    elif [ -z "${job_dirs[$i]}" ] && report_done "${reports[$i]}"; then
      done_flags[$i]=1
      continue
    else
      report_ready_since[$i]=0
    fi
    all_done=0

    if { [ -n "${events[$i]}" ] && [ ! -e "${events[$i]}" ]; } ||
       { [ -n "${trees[$i]}" ] && [ ! -e "${trees[$i]}" ]; }; then
      printf 'WATCHDOG: INTEGRATED %s\n' "${ids[$i]}"
      exit 2
    fi

    ev=$(fsize "${events[$i]}")
    rp=$(fsize "${reports[$i]}")
    er=$(fsize "${stderr_files[$i]}")
    sz=$((ev + rp + er))
    cpu=$(cpu_sum "${trees[$i]}")
    if [ "$sz" -gt "${sizes[$i]}" ]; then
      sizes[$i]=$sz
      growth[$i]=$(now)
    fi
    mins=$(awk -v a="$(now)" -v b="${growth[$i]}" 'BEGIN{printf "%.3f",(a-b)/60}')
    delta=$((cpu - cpus[$i]))
    cpus[$i]=$cpu
    grace=$(awk -v a="$stall" -v b="${hints[$i]}" 'BEGIN{print a+b}')
    if awk -v m="$mins" -v g="$grace" 'BEGIN{exit !(m>g)}' && [ "$delta" -eq 0 ]; then
      printf 'WATCHDOG: STALL %s minutes_since_growth=%s cpu_delta=%s\n' "${ids[$i]}" "$mins" "$delta"
      tail_text "${events[$i]}" | tail -n 5
      exit 3
    fi

    last4=$(tail_text "${events[$i]}" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tail -n 4)
    if [ "$(printf '%s\n' "$last4" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 4 ] &&
       [ "$(printf '%s\n' "$last4" | sort -u | wc -l | tr -d ' ')" -eq 1 ]; then
      printf 'WATCHDOG: REPEAT %s command=%s count=4\n' "${ids[$i]}" "$(printf '%s\n' "$last4" | sed -n '1p')"
      exit 4
    fi
  done

  if [ "$all_done" -eq 1 ]; then
    printf 'WATCHDOG: ALL_DONE\n'
    for i in "${!ids[@]}"; do
      printf '%s %s %s bytes\n' "${ids[$i]}" "${reports[$i]}" "$(fsize "${reports[$i]}")"
    done
    exit 0
  fi
  sleep "$sweep"
done
