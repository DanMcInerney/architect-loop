#!/usr/bin/env bash
set -u

out=
tmp=
tmp_base=
tmp_files=()
add_tmp(){ tmp_files[${#tmp_files[@]}]=$1; }
cleanup_tmp(){ for f in "${tmp_files[@]}"; do [ -n "$f" ] && rm -f "$f"; done; }
die(){
  cleanup_tmp
  [ -n "${out:-}" ] && rm -f "$out"
  [ -n "${tmp:-}" ] && rm -f "$tmp"
  printf 'CHECKRUN: ERROR %s\n' "$1"
  exit 5
}
make_tmp(){
  [ -n "$tmp_base" ] || die "tmp unavailable"
  mktemp "$tmp_base/$1.XXXXXX" 2>/dev/null || die "tmp unavailable"
}
trim_left(){
  trim_left_result=$1
  while :; do
    case "$trim_left_result" in ' '*) trim_left_result=${trim_left_result#?};; $'\t'*) trim_left_result=${trim_left_result#?};; *) break;; esac
  done
}
parse_expectation(){
  parse_tail=$1
  parse_line=$2
  trim_left "$parse_tail"
  parse_tail=$trim_left_result
  case "$parse_tail" in
    '->'*) parse_tail=${parse_tail#'->'};;
    *) die "missing RUN expectation $check_file:$parse_line";;
  esac
  trim_left "$parse_tail"
  parse_tail=$trim_left_result
  case "$parse_tail" in
    exit:[0-9]*)
      parse_after_exit=${parse_tail#exit:}
      parse_exit=${parse_after_exit%%[!0-9]*}
      [ -n "$parse_exit" ] || die "missing RUN expectation $check_file:$parse_line"
      parse_rest=${parse_after_exit#"$parse_exit"}
      parse_expected="exit:$parse_exit"
      parse_match=
      parse_has_match=false
      trim_left "$parse_rest"
      parse_rest=$trim_left_result
      case "$parse_rest" in
        match:\"*)
          parse_after_match=${parse_rest#match:\"}
          case "$parse_after_match" in
            *\"*)
              parse_match=${parse_after_match%%\"*}
              parse_has_match=true
              parse_expected="$parse_expected match:\"$parse_match\""
              ;;
            *) die "malformed RUN match expectation $check_file:$parse_line";;
          esac
          ;;
      esac
      ;;
    *) die "missing RUN expectation $check_file:$parse_line";;
  esac
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
[ -n "$workdir" ] || die "missing workdir"
tmp_base="$workdir/.architect/tmp/check-runner"
mkdir -p "$tmp_base" 2>/dev/null || die "tmp unavailable"

disk_hash=$(git hash-object -- "$check_file" 2>/dev/null || printf '')
freeze_hash=$(git rev-parse "$freeze_sha:$check_file" 2>/dev/null || printf '')
check_match=false
[ -n "$disk_hash" ] && [ -n "$freeze_hash" ] && [ "$disk_hash" = "$freeze_hash" ] && check_match=true
head=$(git -C "$workdir" rev-parse HEAD 2>/dev/null || printf '')
changed_tmp=$(make_tmp changed); add_tmp "$changed_tmp"
git -C "$workdir" diff --name-only "$freeze_sha..HEAD" > "$changed_tmp" 2>/dev/null || :
changed_count=$(awk 'NF{n++} END{print n+0}' "$changed_tmp")
docs_touched=$(awk 'BEGIN{x="false"} /^docs\/checks\//{x="true"} END{print x}' "$changed_tmp")

bt='`'
section='(root)'
executor_header=
line_no=0
count=0
declare -a sections line_numbers commands expected_exits expected_texts expected_matches expected_has_matches
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
          tail=${after#*"$bt"}
          parse_expectation "$tail" "$line_no"
          sections[$count]=$section
          line_numbers[$count]=$line_no
          commands[$count]=$cmd
          expected_exits[$count]=$parse_exit
          expected_texts[$count]=$parse_expected
          expected_matches[$count]=$parse_match
          expected_has_matches[$count]=$parse_has_match
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
  pass_count=0
  fail_count=0
  i=0
  while [ "$i" -lt "$count" ]; do
    run_out=$(make_tmp run); add_tmp "$run_out"
    run_stdout=$(make_tmp stdout); add_tmp "$run_stdout"
    run_stderr=$(make_tmp stderr); add_tmp "$run_stderr"
    start=$(now_ms)
    if [ "$executor" = powershell ]; then
      (cd "$workdir" && powershell -NoProfile -Command "${commands[$i]}") > "$run_stdout" 2> "$run_stderr"
      code=$?
    else
      (cd "$workdir" && bash -c "${commands[$i]}") > "$run_stdout" 2> "$run_stderr"
      code=$?
    fi
    end=$(now_ms)
    ms=$((end - start))
    cat "$run_stdout" "$run_stderr" > "$run_out"
    verdict=PASS
    [ "$code" = "${expected_exits[$i]}" ] || verdict=FAIL
    if [ "${expected_has_matches[$i]}" = true ]; then
      if CHECKRUN_EXPECTED_MATCH=${expected_matches[$i]} awk '
        BEGIN {
          needle = ENVIRON["CHECKRUN_EXPECTED_MATCH"]
          found = (needle == "")
        }
        {
          if (NR > 1) { stdout_text = stdout_text "\n" }
          stdout_text = stdout_text $0
        }
        END {
          if (!found && index(stdout_text, needle) > 0) { found = 1 }
          exit(found ? 0 : 1)
        }
      ' "$run_stdout"; then
        :
      else
        verdict=FAIL
      fi
    fi
    if [ "$verdict" = PASS ]; then pass_count=$((pass_count + 1)); else fail_count=$((fail_count + 1)); fi
    bytes=$(wc -c < "$run_out" | tr -d ' ')
    total_lines=$(awk 'END{print NR}' "$run_out")
    mark=
    [ "$total_lines" -gt "$max_output_lines" ] && mark=' truncated'
    printf '\n## %s line %s\n' "${sections[$i]}" "${line_numbers[$i]}"
    printf '$ %s\n' "${commands[$i]}"
    printf 'exit: %s  ms: %s  bytes: %s%s\n' "$code" "$ms" "$bytes" "$mark"
    printf 'expected: %s\n' "${expected_texts[$i]}"
    printf 'verdict: %s\n' "$verdict"
    sed -n "1,${max_output_lines}p" "$run_out"
    rm -f "$run_out" "$run_stdout" "$run_stderr"
    i=$((i + 1))
  done
  printf '\nCHECKRUN SUMMARY: run_items=%s pass=%s fail=%s\n' "$count" "$pass_count" "$fail_count"
  printf 'integrity: check_file_matches_freeze=%s head=%s\n' "$check_match" "$head"
  printf 'changed_files: %s listed below; docs_checks_touched=%s\n' "$changed_count" "$docs_touched"
  cat "$changed_tmp"
} > "$tmp"

mv "$tmp" "$out"
cleanup_tmp
if [ "$fail_count" -gt 0 ]; then exit 2; fi
exit 0
