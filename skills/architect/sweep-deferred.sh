#!/usr/bin/env bash
set -u

run_slug=${1:-}
repo_root=$(pwd)
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-root) repo_root=$2; shift 2;;
    --repo-root=*) repo_root=${1#--repo-root=}; shift;;
    *) shift;;
  esac
done
[ -n "$run_slug" ] || { printf 'SWEEP: ERROR missing run\n'; exit 5; }
case "$run_slug" in *[!A-Za-z0-9._-]*) printf 'SWEEP: ERROR invalid run slug\n'; exit 5;; esac
case "$repo_root" in [A-Za-z]:\\*) if command -v cygpath >/dev/null 2>&1; then repo_root=$(cygpath -u "$repo_root"); fi;; esac
case "$repo_root" in /*) ;; *) repo_root="$(pwd)/$repo_root";; esac
[ -d "$repo_root" ] || { printf 'SWEEP: ERROR repo root missing\n'; exit 5; }

wt_root="$repo_root/.architect/wt/$run_slug"
deferred="$repo_root/docs/runs/$run_slug/deferred-cleanup.txt"
targets_tmp=$(mktemp "${TMPDIR:-/tmp}/sweep-targets.XXXXXX") || { printf 'SWEEP: ERROR tmp unavailable\n'; exit 5; }
trap 'rm -f "$targets_tmp"' EXIT
[ -d "$wt_root" ] && find "$wt_root" -mindepth 1 -maxdepth 1 -type d >> "$targets_tmp"
if [ -f "$deferred" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    case "$line" in [A-Za-z]:\\*) if command -v cygpath >/dev/null 2>&1; then line=$(cygpath -u "$line"); fi;; esac
    case "$line" in /*) printf '%s\n' "$line";; *) printf '%s/%s\n' "$repo_root" "$line";; esac
  done < "$deferred" >> "$targets_tmp"
fi

removed=0
locked=
while IFS= read -r target || [ -n "$target" ]; do
  [ -n "$target" ] || continue
  case "$target" in "$wt_root"/*) ;; *) continue;; esac
  [ -e "$target" ] || continue
  git -C "$repo_root" worktree remove --force "$target" >/dev/null 2>&1 || :
  if [ -e "$target" ]; then chmod -R u+w "$target" 2>/dev/null || :; rm -rf "$target" 2>/dev/null || :; fi
  if [ -e "$target" ]; then locked="${locked:+$locked,}$target"; else removed=$((removed + 1)); fi
done < "$targets_tmp"

if [ -n "$locked" ]; then printf 'SWEEP: PARTIAL removed=%s locked=%s\n' "$removed" "$locked"; exit 2; fi
printf 'SWEEP: OK removed=%s\n' "$removed"
exit 0
