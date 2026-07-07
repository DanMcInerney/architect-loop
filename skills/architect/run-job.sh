#!/usr/bin/env bash
set -u

job_dir=
workdir=
backend=cli
report_path=
events_file=
stdin_file=
heartbeat_sec=30

while [ "$#" -gt 0 ]; do
  case "$1" in
    --job-dir) job_dir=$2; shift 2;;
    --workdir) workdir=$2; shift 2;;
    --backend) backend=$2; shift 2;;
    --report-path) report_path=$2; shift 2;;
    --events-file) events_file=$2; shift 2;;
    --stdin-file) stdin_file=$2; shift 2;;
    --heartbeat-sec) heartbeat_sec=$2; shift 2;;
    --) shift; break;;
    *) break;;
  esac
done

[ -n "$job_dir" ] || { printf 'RUNJOB: ERROR missing --job-dir\n'; exit 64; }
[ -n "$workdir" ] || { printf 'RUNJOB: ERROR missing --workdir\n'; exit 64; }
[ "$#" -gt 0 ] || { printf 'RUNJOB: ERROR missing command\n'; exit 64; }
[ -n "$events_file" ] || events_file="$job_dir/events.jsonl"

json_escape(){
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}
now_iso(){ date -u '+%Y-%m-%dT%H:%M:%SZ'; }
write_heartbeat(){ printf '%s\n' "$(now_iso)" > "$job_dir/job.heartbeat"; }
write_exit(){ printf '{"exit_code":%s,"ended_at":"%s"}\n' "$1" "$(now_iso)" > "$job_dir/job.exit.json"; }
command_json(){
  first=true
  printf '['
  for arg in "$@"; do
    [ "$first" = true ] || printf ','
    first=false
    printf '"%s"' "$(json_escape "$arg")"
  done
  printf ']'
}

mkdir -p "$job_dir" "$(dirname "$events_file")" || exit 64
: > "$events_file" || exit 64

(
  printf '{'
  printf '"backend":"%s",' "$(json_escape "$backend")"
  printf '"command":'
  command_json "$@"
  printf ',"cwd":"%s",' "$(json_escape "$workdir")"
  printf '"events_file":"%s",' "$(json_escape "$events_file")"
  printf '"report_path":"%s",' "$(json_escape "$report_path")"
  printf '"job_dir":"%s",' "$(json_escape "$job_dir")"
  printf '"wrapper_pid":%s,' "$$"
  printf '"started_at":"%s"' "$(now_iso)"
  printf '}\n'
) > "$job_dir/job.meta.json"

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

wait_file="$job_dir/job.wait"
wait_tmp="$job_dir/job.wait.tmp"
rm -f "$wait_file" "$wait_tmp"
(
  if [ -n "$stdin_file" ]; then
    "$@" < "$stdin_file" > "$events_file" 2>&1
  else
    "$@" > "$events_file" 2>&1
  fi
  child_code=$?
  printf '%s\n' "$child_code" > "$wait_tmp"
  mv "$wait_tmp" "$wait_file"
  exit "$child_code"
) &
child=$!
tmp_meta="$job_dir/job.meta.json.tmp"
sed "s/\"started_at\"/\"child_pid\":$child,\"started_at\"/" "$job_dir/job.meta.json" > "$tmp_meta" && mv "$tmp_meta" "$job_dir/job.meta.json"

trap 'exit 143' INT TERM HUP

write_heartbeat
last_heartbeat=$(date +%s)
while [ ! -f "$wait_file" ]; do
  sleep 1
  now_epoch=$(date +%s)
  if [ $((now_epoch - last_heartbeat)) -ge "$heartbeat_sec" ]; then
    write_heartbeat
    last_heartbeat=$now_epoch
  fi
done
wait "$child" 2>/dev/null || true
code=$(cat "$wait_file" 2>/dev/null || printf 127)
rm -f "$wait_file" "$wait_tmp"
trap - INT TERM HUP
write_heartbeat
write_exit "$code"
exit "$code"
