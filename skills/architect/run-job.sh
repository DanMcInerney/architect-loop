#!/usr/bin/env bash
set -u

job_dir=
workdir=
backend=cli
report_path=
events_file=
stdin_file=
heartbeat_sec=30
sandbox_env=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --job-dir) job_dir=$2; shift 2;;
    --workdir) workdir=$2; shift 2;;
    --backend) backend=$2; shift 2;;
    --report-path) report_path=$2; shift 2;;
    --events-file) events_file=$2; shift 2;;
    --stdin-file) stdin_file=$2; shift 2;;
    --heartbeat-sec) heartbeat_sec=$2; shift 2;;
    --sandbox-env) sandbox_env=true; shift;;
    --) shift; break;;
    *) break;;
  esac
done

[ -n "$job_dir" ] || { printf 'RUNJOB: ERROR missing --job-dir\n'; exit 64; }
[ -n "$workdir" ] || { printf 'RUNJOB: ERROR missing --workdir\n'; exit 64; }
[ "$#" -gt 0 ] || { printf 'RUNJOB: ERROR missing command\n'; exit 64; }
[ -n "$events_file" ] || events_file="$job_dir/events.jsonl"
stderr_file="$job_dir/stderr.log"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

now_iso() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

write_heartbeat() {
  printf '%s\n' "$(now_iso)" > "$job_dir/job.heartbeat"
}

write_exit() {
  printf '{"exit_code":%s,"ended_at":"%s"}\n' "$1" "$(now_iso)" > "$job_dir/job.exit.json"
}

command_json() {
  first=true
  printf '['
  for arg in "$@"; do
    [ "$first" = true ] || printf ','
    first=false
    printf '"%s"' "$(json_escape "$arg")"
  done
  printf ']'
}

mkdir -p "$job_dir" "$(dirname "$events_file")" "$(dirname "$stderr_file")" || exit 64
: > "$events_file" || exit 64
: > "$stderr_file" || exit 64

{
  printf '{'
  printf '"backend":"%s",' "$(json_escape "$backend")"
  printf '"command":'
  command_json "$@"
  printf ',"cwd":"%s",' "$(json_escape "$workdir")"
  printf '"events_file":"%s",' "$(json_escape "$events_file")"
  printf '"stderr_file":"%s",' "$(json_escape "$stderr_file")"
  printf '"report_path":"%s",' "$(json_escape "$report_path")"
  printf '"job_dir":"%s",' "$(json_escape "$job_dir")"
  printf '"wrapper_pid":%s,' "$$"
  printf '"sandbox_env":%s,' "$sandbox_env"
  if [ "$sandbox_env" = true ]; then
    printf '"sandbox_tmp":"%s",' "$(json_escape "$workdir/.architect/tmp/env")"
    printf '"sandbox_uv_cache":"%s",' "$(json_escape "$workdir/.architect/tmp/uv-cache")"
  fi
  printf '"started_at":"%s"' "$(now_iso)"
  printf '}\n'
} > "$job_dir/job.meta.json"

if [ ! -d "$workdir" ]; then
  write_exit 127
  printf 'RUNJOB: ERROR missing workdir\n'
  exit 127
fi

if [ -n "$stdin_file" ] && [ ! -f "$stdin_file" ]; then
  write_exit 127
  printf 'RUNJOB: ERROR missing stdin file\n'
  exit 127
fi

if [ "$sandbox_env" = true ]; then
  mkdir -p "$workdir/.architect/tmp/env" "$workdir/.architect/tmp/uv-cache" || exit 64
fi

wait_file="$job_dir/job.wait"
wait_tmp="$job_dir/job.wait.tmp"
child_pid_file="$job_dir/job.child"
child_pid_tmp="$job_dir/job.child.tmp"
kill_request="$job_dir/job.kill"
rm -f "$wait_file" "$wait_tmp" "$child_pid_file" "$child_pid_tmp" "$kill_request"

use_setsid=false
if [ "${ARCHITECT_RUN_JOB_DISABLE_SETSID:-}" != 1 ]; then
  command -v setsid >/dev/null 2>&1 && use_setsid=true
fi

(
  if [ "$sandbox_env" = true ]; then
    export TEMP="$workdir/.architect/tmp/env"
    export TMP="$workdir/.architect/tmp/env"
    export TMPDIR="$workdir/.architect/tmp/env"
    export UV_CACHE_DIR="$workdir/.architect/tmp/uv-cache"
  fi

  if [ "$use_setsid" = true ]; then
    launcher=$(command -v bash 2>/dev/null || printf bash)
    if [ -n "$stdin_file" ]; then
      setsid "$launcher" -c 'printf "%s\n" "$$" > "$1"; mv "$1" "$2"; shift 2; exec "$@"' architect-scope "$child_pid_tmp" "$child_pid_file" "$@" < "$stdin_file" > "$events_file" 2> "$stderr_file" &
    else
      setsid "$launcher" -c 'printf "%s\n" "$$" > "$1"; mv "$1" "$2"; shift 2; exec "$@"' architect-scope "$child_pid_tmp" "$child_pid_file" "$@" > "$events_file" 2> "$stderr_file" &
    fi
    inner=$!
    wait "$inner" 2>/dev/null
    child_code=$?
  else
    if [ -n "$stdin_file" ]; then
      "$@" < "$stdin_file" > "$events_file" 2> "$stderr_file" &
    else
      "$@" > "$events_file" 2> "$stderr_file" &
    fi
    inner=$!
    printf '%s\n' "$inner" > "$child_pid_tmp"
    mv "$child_pid_tmp" "$child_pid_file"
    wait "$inner" 2>/dev/null
    child_code=$?
  fi
  printf '%s\n' "$child_code" > "$wait_tmp"
  mv "$wait_tmp" "$wait_file"
  exit "$child_code"
) &
child=$!
child_meta=$child
pgid_json=null
scope=plain
deadline=$(( $(date +%s) + 5 ))
while [ ! -f "$child_pid_file" ] && [ "$(date +%s)" -lt "$deadline" ]; do
  sleep 0.05
done
if [ -f "$child_pid_file" ]; then
  child_meta=$(cat "$child_pid_file" 2>/dev/null || printf '%s' "$child")
fi
if [ "$use_setsid" = true ]; then
  pgid_json=$child_meta
  scope=setsid
fi
tmp_meta="$job_dir/job.meta.json.tmp"
sed "s/\"started_at\"/\"child_pid\":$child_meta,\"pgid\":$pgid_json,\"spawn_scope\":\"$scope\",\"started_at\"/" "$job_dir/job.meta.json" > "$tmp_meta" && mv "$tmp_meta" "$job_dir/job.meta.json"

trap 'exit 143' INT TERM HUP

write_heartbeat
last_heartbeat=$(date +%s)
kill_sent=false
kill_at=0
while [ ! -f "$wait_file" ]; do
  sleep 1
  now_epoch=$(date +%s)
  if ! kill -0 "$child" 2>/dev/null; then
    wait "$child" 2>/dev/null
    child_code=$?
    if [ ! -f "$wait_file" ]; then
      printf '%s\n' "$child_code" > "$wait_tmp"
      mv "$wait_tmp" "$wait_file"
    fi
    continue
  fi
  if [ -f "$kill_request" ] && [ "$kill_sent" = false ]; then
    if [ "$pgid_json" != null ]; then
      kill -TERM -- "-$pgid_json" 2>/dev/null || :
    else
      kill -TERM "$child_meta" 2>/dev/null || :
    fi
    kill_sent=true
    kill_at=$now_epoch
  elif [ "$kill_sent" = true ] && [ $((now_epoch - kill_at)) -ge 5 ]; then
    if [ "$pgid_json" != null ]; then
      kill -KILL -- "-$pgid_json" 2>/dev/null || :
    else
      kill -KILL "$child_meta" 2>/dev/null || :
    fi
  fi
  if [ $((now_epoch - last_heartbeat)) -ge "$heartbeat_sec" ]; then
    write_heartbeat
    last_heartbeat=$now_epoch
  fi
done

wait "$child" 2>/dev/null || true
code=$(cat "$wait_file" 2>/dev/null || printf 127)
rm -f "$wait_file" "$wait_tmp" "$child_pid_file" "$child_pid_tmp" "$kill_request"
trap - INT TERM HUP
write_heartbeat
write_exit "$code"
exit "$code"
