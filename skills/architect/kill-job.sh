#!/usr/bin/env bash
set -u

job_dir=${1:-}
[ -n "$job_dir" ] || { printf 'KILLJOB: ERROR missing job dir\n'; exit 5; }
case "$job_dir" in
  [A-Za-z]:\\*) command -v cygpath >/dev/null 2>&1 && job_dir=$(cygpath -u "$job_dir");;
esac
meta="$job_dir/job.meta.json"
[ -r "$meta" ] || { printf 'KILLJOB: ERROR missing metadata\n'; exit 5; }

field() {
  tr -d '\r\n' < "$meta" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" | tail -n 1
}

pgid=$(field pgid)
pid=$(field child_pid)
reaped=0

wait_gone() {
  target=$1
  i=0
  while [ "$i" -lt 20 ]; do
    if ! kill -0 -- "$target" 2>/dev/null; then
      return 0
    fi
    sleep 0.25
    i=$((i + 1))
  done
  return 1
}

if [ -n "$pgid" ] && [ "$pgid" != null ] && [ "$pgid" -gt 0 ] 2>/dev/null; then
  if kill -TERM -- "-$pgid" 2>/dev/null; then
    reaped=1
    wait_gone "-$pgid" || kill -KILL -- "-$pgid" 2>/dev/null || :
    printf 'KILLJOB: OK %s reaped=%s\n' "$(basename "$job_dir")" "$reaped"
    exit 0
  fi
fi

if [ -n "$pid" ] && [ "$pid" -gt 0 ] 2>/dev/null; then
  if kill -TERM -- "$pid" 2>/dev/null; then
    reaped=1
    wait_gone "$pid" || kill -KILL -- "$pid" 2>/dev/null || :
    printf 'KILLJOB: OK %s reaped=%s\n' "$(basename "$job_dir")" "$reaped"
    exit 0
  fi
  if command -v taskkill.exe >/dev/null 2>&1; then
    if taskkill.exe /F /T /PID "$pid" >/dev/null 2>&1; then
      printf 'KILLJOB: OK %s reaped=1\n' "$(basename "$job_dir")"
      exit 0
    fi
  fi
fi

printf '%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$job_dir/job.kill" 2>/dev/null || :
i=0
while [ "$i" -lt 40 ]; do
  if [ -f "$job_dir/job.exit.json" ]; then
    printf 'KILLJOB: OK %s reaped=1\n' "$(basename "$job_dir")"
    exit 0
  fi
  sleep 0.25
  i=$((i + 1))
done

printf 'KILLJOB: ERROR no kill scope\n'
exit 5
