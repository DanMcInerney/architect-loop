#!/usr/bin/env bash
set -u

out=
tmp=
die(){
  [ -n "${out:-}" ] && rm -f "$out"
  [ -n "${tmp:-}" ] && rm -f "$tmp"
  printf 'CHECKRUN: ERROR %s\n' "$1"
  exit 5
}

cfg=${1:-}
[ -n "$cfg" ] || die "unreadable config"
[ -r "$cfg" ] || die "unreadable config"
json=$(tr -d '\r\n' < "$cfg") || die "unreadable config"
field(){ printf '%s' "$json" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }
numfield(){ printf '%s' "$json" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p"; }

check_file=$(field check_file)
workdir=$(field workdir)
freeze_sha=$(field freeze_sha)
out=$(field evidence_out)
executor=$(field executor)
max_output_lines=$(numfield max_output_lines)
[ -n "$max_output_lines" ] || max_output_lines=60

[ -f "$check_file" ] || die "missing check file"
git --version >/dev/null 2>&1 || die "git unavailable"

disk_hash=$(git hash-object -- "$check_file" 2>/dev/null || printf '')
freeze_hash=$(git rev-parse "$freeze_sha:$check_file" 2>/dev/null || printf '')
check_match=false
[ -n "$disk_hash" ] && [ -n "$freeze_hash" ] && [ "$disk_hash" = "$freeze_hash" ] && check_match=true
head=$(git -C "$workdir" rev-parse HEAD 2>/dev/null || printf '')
changed_tmp=$(mktemp)
git -C "$workdir" diff --name-only "$freeze_sha..HEAD" > "$changed_tmp" 2>/dev/null || :
changed_count=$(awk 'NF{n++} END{print n+0}' "$changed_tmp")
docs_touched=$(awk 'BEGIN{x="false"} /^docs\/checks\//{x="true"} END{print x}' "$changed_tmp")

bt='`'
section='(root)'
executor_header=
line_no=0
count=0
declare -a sections line_numbers commands
while IFS= read -r line || [ -n "$line" ]; do
  line_no=$((line_no + 1))
  case "$line" in Executor:*) [ -z "$executor_header" ] && executor_header=$line;; esac
  case "$line" in '## '*) section=${line#'## '};; esac
  trimmed=$line
  while :; do
    case "$trimmed" in ' '*) trimmed=${trimmed#?};; $'\t'*) trimmed=${trimmed#?};; *) break;; esac
  done
  case "$trimmed" in
    '- RUN:'*)
      rest=${trimmed#'- RUN:'}
      case "$rest" in
        *"$bt"*"$bt"*)
          after=${rest#*"$bt"}
          cmd=${after%%"$bt"*}
          sections[$count]=$section
          line_numbers[$count]=$line_no
          commands[$count]=$cmd
          count=$((count + 1))
          ;;
      esac
      ;;
  esac
done < "$check_file"

now_ms(){ perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000' 2>/dev/null || printf '%s000\n' "$(date +%s)"; }
out_dir=$(dirname "$out")
[ -d "$out_dir" ] || mkdir -p "$out_dir"
tmp="$out.tmp.$$"
slug=$(basename "$out" .md)

{
  printf '# Checkrun: %s\n' "$slug"
  printf 'generated: %s  runner: sh  config: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$cfg"
  printf 'check_file: %s  freeze_sha: %s\n' "$check_file" "$freeze_sha"
  [ -n "$executor_header" ] && printf '%s\n' "$executor_header"
  printf 'executor_config: %s\n' "$executor"
  printf 'integrity: check_file_matches_freeze=%s head=%s\n' "$check_match" "$head"
  printf 'changed_files: %s listed below; docs_checks_touched=%s\n' "$changed_count" "$docs_touched"
  cat "$changed_tmp"
  i=0
  while [ "$i" -lt "$count" ]; do
    run_out=$(mktemp)
    start=$(now_ms)
    if [ "$executor" = powershell ]; then
      (cd "$workdir" && powershell -NoProfile -Command "${commands[$i]}") > "$run_out" 2>&1
      code=$?
    else
      (cd "$workdir" && bash -c "${commands[$i]}") > "$run_out" 2>&1
      code=$?
    fi
    end=$(now_ms)
    ms=$((end - start))
    bytes=$(wc -c < "$run_out" | tr -d ' ')
    total_lines=$(awk 'END{print NR}' "$run_out")
    mark=
    [ "$total_lines" -gt "$max_output_lines" ] && mark=' truncated'
    printf '\n## %s line %s\n' "${sections[$i]}" "${line_numbers[$i]}"
    printf '$ %s\n' "${commands[$i]}"
    printf 'exit: %s  ms: %s  bytes: %s%s\n' "$code" "$ms" "$bytes" "$mark"
    sed -n "1,${max_output_lines}p" "$run_out"
    rm -f "$run_out"
    i=$((i + 1))
  done
} > "$tmp"

mv "$tmp" "$out"
rm -f "$changed_tmp"
exit 0
