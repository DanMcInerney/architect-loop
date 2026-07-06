#!/usr/bin/env bash
set -u

run_slug=
root=$(pwd)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-root)
      [ "$#" -ge 2 ] || { printf 'missing value for --repo-root\n'; exit 1; }
      root=$2
      shift 2
      ;;
    --repo-root=*)
      root=${1#--repo-root=}
      shift
      ;;
    -*)
      printf 'unknown argument: %s\n' "$1"
      exit 1
      ;;
    *)
      [ -z "$run_slug" ] || { printf 'unexpected positional argument: %s\n' "$1"; exit 1; }
      run_slug=$1
      shift
      ;;
  esac
done

case "$root" in /*) ;; *) root="$(pwd)/$root";; esac
state_root="$root/.scratch/architect-loop/state"

tail_status() {
  [ -f "$1" ] || return 1
  tail -n 20 "$1" | awk '/^STATUS:/{s=$0} END{if(s) print s}'
}

print_slice() {
  slice_dir=$1
  slice=$(basename "$slice_dir")
  manifest="$slice_dir/manifest.json"
  verdict="$slice_dir/verdict.md"
  base=unknown
  final_patch="$slice_dir/final.patch"
  [ -f "$manifest" ] && base=$(sed -n 's/.*"base_sha"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | sed -n '1p')
  printf 'SLICE %s base=%s\n' "$slice" "${base:-unknown}"
  if [ -s "$final_patch" ]; then
    printf '  final_patch: %s (%s bytes)\n' "$final_patch" "$(wc -c < "$final_patch" | tr -d ' ')"
  fi
  if [ -f "$verdict" ]; then
    printf '  verdict: %s\n' "$verdict"
  fi
  if [ -d "$slice_dir/reports" ]; then
    for report in "$slice_dir"/reports/*.md; do
      [ -f "$report" ] || continue
      status=$(tail_status "$report" || true)
      printf '  report: %s %s\n' "$(basename "$report")" "${status:-STATUS: unknown}"
    done
  fi
  if [ -d "$slice_dir/checks" ]; then
    for check in "$slice_dir"/checks/*-checkrun.md; do
      [ -f "$check" ] || continue
      summary=$(grep 'CHECKRUN SUMMARY:' "$check" | tail -n 1)
      printf '  check: %s %s\n' "$(basename "$check")" "${summary:-CHECKRUN SUMMARY: missing}"
    done
  fi
}

if [ ! -d "$state_root" ]; then
  printf 'NO LOCAL ARCHITECT RUNS\n'
  exit 0
fi

if [ -n "$run_slug" ]; then
  dir="$state_root/$run_slug"
  [ -d "$dir" ] || { printf 'NO SUCH LOCAL ARCHITECT RUN: %s\n' "$run_slug"; exit 1; }
  print_slice "$dir"
  exit 0
fi

found=0
for dir in "$state_root"/*; do
  [ -d "$dir" ] || continue
  found=1
  print_slice "$dir"
done

[ "$found" -eq 1 ] || printf 'NO LOCAL ARCHITECT RUNS\n'
