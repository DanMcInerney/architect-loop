#!/usr/bin/env bash
set -u

cfg=${1:-}
evidence_out=
tmp_out=

die() {
  [ -n "${tmp_out:-}" ] && rm -f "$tmp_out"
  [ -n "${evidence_out:-}" ] && rm -f "$evidence_out"
  printf 'CHECKRUN: ERROR %s\n' "$1"
  exit 5
}

[ -n "$cfg" ] && [ -r "$cfg" ] || die "unreadable config"
json=$(tr -d '\r\n' < "$cfg") || die "unreadable config"
field() { printf '%s' "$json" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }
numfield() { printf '%s' "$json" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p"; }

check_file=$(field check_file)
frozen_check_file=$(field frozen_check_file)
workdir=$(field workdir)
base_sha=$(field base_sha)
evidence_out=$(field evidence_out)
executor=$(field executor)
max_output_lines=$(numfield max_output_lines)

[ -n "$check_file" ] || die "missing check_file"
[ -n "$frozen_check_file" ] || die "missing frozen_check_file"
[ -n "$workdir" ] || die "missing workdir"
[ -n "$evidence_out" ] || die "missing evidence_out"
[ -n "$executor" ] || executor=bash
[ -n "$max_output_lines" ] || max_output_lines=60
[ "$executor" = "bash" ] || die "unsupported executor $executor"
[ -r "$check_file" ] || die "unreadable check_file"
[ -r "$frozen_check_file" ] || die "unreadable frozen_check_file"
[ -d "$workdir" ] || die "missing workdir"

tmp_base="$workdir/.scratch/architect-loop/tmp/check-runner"
mkdir -p "$tmp_base" || die "tmp unavailable"
tmp_out="$evidence_out.tmp.$$"
mkdir -p "$(dirname "$evidence_out")" || die "evidence directory unavailable"

integrity=false
if cmp -s "$check_file" "$frozen_check_file"; then
  integrity=true
fi

head_sha=$(git -C "$workdir" rev-parse HEAD 2>/dev/null || printf 'unknown')
changed_file="$tmp_base/changed.$$"
if [ -n "$base_sha" ]; then
  git -C "$workdir" diff --name-only "$base_sha..HEAD" > "$changed_file" 2>/dev/null || :
else
  : > "$changed_file"
fi

run_items=0
pass_items=0
fail_items=0

{
  printf '# Checkrun Evidence\n\n'
  printf 'check_file: %s\n' "$check_file"
  printf 'frozen_check_file: %s\n' "$frozen_check_file"
  printf 'workdir: %s\n' "$workdir"
  printf 'base_sha: %s\n' "${base_sha:-none}"
  printf 'head_sha: %s\n' "$head_sha"
  printf 'integrity: check_file_matches_frozen=%s\n\n' "$integrity"
} > "$tmp_out"

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    *RUN:*)
      if [[ "$line" =~ RUN:[[:space:]]*\`([^\`]*)\`[[:space:]]*-\>[[:space:]]*exit:([0-9]+)([[:space:]]+match:\"([^\"]*)\")? ]]; then
        cmd=${BASH_REMATCH[1]}
        expected_exit=${BASH_REMATCH[2]}
        has_match=false
        match_text=
        if [ -n "${BASH_REMATCH[4]:-}" ]; then
          has_match=true
          match_text=${BASH_REMATCH[4]}
        fi
      else
        die "missing RUN expectation in $check_file"
      fi

      run_items=$((run_items + 1))
      stdout_file="$tmp_base/stdout.$run_items.$$"
      stderr_file="$tmp_base/stderr.$run_items.$$"
      (cd "$workdir" && bash -c "$cmd") > "$stdout_file" 2> "$stderr_file"
      actual_exit=$?
      stdout_text=$(cat "$stdout_file")
      verdict=PASS
      if [ "$actual_exit" -ne "$expected_exit" ]; then
        verdict=FAIL
      fi
      if [ "$has_match" = true ] && [[ "$stdout_text" != *"$match_text"* ]]; then
        verdict=FAIL
      fi
      if [ "$verdict" = PASS ]; then
        pass_items=$((pass_items + 1))
      else
        fail_items=$((fail_items + 1))
      fi

      {
        printf '## RUN %s\n\n' "$run_items"
        printf 'command: `%s`\n' "$cmd"
        if [ "$has_match" = true ]; then
          printf 'expected: exit:%s match:"%s"\n' "$expected_exit" "$match_text"
        else
          printf 'expected: exit:%s\n' "$expected_exit"
        fi
        printf 'actual_exit: %s\n' "$actual_exit"
        printf 'verdict: %s\n\n' "$verdict"
        printf 'stdout_tail:\n```text\n'
        tail -n "$max_output_lines" "$stdout_file"
        printf '\n```\n\nstderr_tail:\n```text\n'
        tail -n "$max_output_lines" "$stderr_file"
        printf '\n```\n\n'
      } >> "$tmp_out"

      rm -f "$stdout_file" "$stderr_file"
      ;;
  esac
done < "$check_file"

{
  printf '## Changed Files Since Base\n\n'
  cat "$changed_file"
  printf '\nCHECKRUN SUMMARY: run_items=%s pass=%s fail=%s\n' "$run_items" "$pass_items" "$fail_items"
} >> "$tmp_out"

rm -f "$changed_file"
mv "$tmp_out" "$evidence_out" || die "could not write evidence"
tmp_out=

if [ "$fail_items" -gt 0 ] || [ "$integrity" != true ]; then
  exit 2
fi
exit 0
