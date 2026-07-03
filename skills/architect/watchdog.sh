#!/usr/bin/env bash
set -u

cfg=
while [ "$#" -gt 0 ]; do
  case "$1" in -Config) cfg=$2; shift 2;; *) shift;; esac
done
[ -n "$cfg" ] || exit 1
json=$(tr -d '\r\n' < "$cfg")
sweep=$(printf '%s' "$json" | sed -n 's/.*"sweep_sec"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
stall=$(printf '%s' "$json" | sed -n 's/.*"stall_after_min"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
jobs=$(printf '%s' "$json" | sed 's/.*"jobs"[[:space:]]*:[[:space:]]*\[//;s/\][^]]*$//;s/}[[:space:]]*,[[:space:]]*{/\}\n\{/g')
field(){ printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }
numfield(){ printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p"; }
fsize(){ stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || printf 0; }
now(){ date +%s; }
tail_text(){ [ -f "$1" ] && tail -c 4096 "$1" | tr -d '\000\377\376'; }
report_done(){ [ -f "$1" ] || return 1; last=$(tail_text "$1" | awk 'NF{line=$0} END{gsub(/^[[:space:]]+|[[:space:]]+$/,"",line); print line}'); case "$last" in STATUS:*) return 0;; *) return 1;; esac; }
cpu_sum(){
  w=$1
  if [ -d /proc ]; then
    total=0
    for p in /proc/[0-9]*; do
      [ -r "$p/cmdline" ] || continue
      cmd=$(tr '\000' ' ' < "$p/cmdline")
      case "$cmd" in *"$w"*) v=$(awk '{print $14+$15}' "$p/stat" 2>/dev/null); total=$((total+${v:-0}));; esac
    done
    printf '%s' "$total"
  else
    ps -eo time=,args= | awk -v w="$w" 'index($0,w){split($1,a,":"); n=split($1,b,"-"); t=(n==2?b[2]:$1); split(t,c,":"); if(length(c)==3)s+=c[1]*3600+c[2]*60+c[3]; else s+=c[1]*60+c[2]} END{print s+0}'
  fi
}

declare -a ids events reports trees hints done sizes growth cpus
i=0
while IFS= read -r job; do
  ids[$i]=$(field "$job" id); events[$i]=$(field "$job" events_file)
  reports[$i]=$(field "$job" report_path); trees[$i]=$(field "$job" worktree)
  hints[$i]=$(numfield "$job" duration_hint_min); done[$i]=0
  ev=$(fsize "${events[$i]}"); rp=$(fsize "${reports[$i]}"); sizes[$i]=$((ev+rp)); growth[$i]=$(now); cpus[$i]=$(cpu_sum "${trees[$i]}")
  i=$((i+1))
done <<EOF
$jobs
EOF

while :; do
  all=1
  for i in "${!ids[@]}"; do
    [ "${done[$i]}" = 1 ] && continue
    report_done "${reports[$i]}" && { done[$i]=1; continue; }
    all=0
    if [ ! -e "${events[$i]}" ] && [ ! -e "${trees[$i]}" ]; then
      printf 'WATCHDOG: INTEGRATED %s\n' "${ids[$i]}"; exit 2
    fi
    ev=$(fsize "${events[$i]}"); rp=$(fsize "${reports[$i]}"); sz=$((ev+rp)); cpu=$(cpu_sum "${trees[$i]}")
    [ "$sz" -gt "${sizes[$i]}" ] && { sizes[$i]=$sz; growth[$i]=$(now); }
    mins=$(awk -v a="$(now)" -v b="${growth[$i]}" 'BEGIN{printf "%.3f",(a-b)/60}')
    delta=$((cpu-cpus[$i])); cpus[$i]=$cpu
    grace=$(awk -v a="$stall" -v b="${hints[$i]:-0}" 'BEGIN{print a+b}')
    if awk -v m="$mins" -v g="$grace" 'BEGIN{exit !(m>g)}' && [ "$delta" -eq 0 ]; then
      printf 'WATCHDOG: STALL %s minutes_since_growth=%s cpu_delta=%s\n' "${ids[$i]}" "$mins" "$delta"
      tail_text "${events[$i]}" | tail -n 5; exit 3
    fi
    last4=$(tail_text "${events[$i]}" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tail -n 4)
    if [ "$(printf '%s\n' "$last4" | sed '/^$/d' | wc -l)" -eq 4 ] && [ "$(printf '%s\n' "$last4" | sort -u | wc -l)" -eq 1 ]; then
      printf 'WATCHDOG: REPEAT %s command=%s count=4\n' "${ids[$i]}" "$(printf '%s\n' "$last4" | sed -n '1p')"; exit 4
    fi
  done
  if [ "$all" -eq 1 ]; then
    printf 'WATCHDOG: ALL_DONE\n'
    for i in "${!ids[@]}"; do printf '%s %s %s bytes\n' "${ids[$i]}" "${reports[$i]}" "$(fsize "${reports[$i]}")"; done
    exit 0
  fi
  sleep "$sweep"
done
