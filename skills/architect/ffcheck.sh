#!/usr/bin/env bash
set -u

expected=${1:-}

fail(){ printf 'FFCHECK: ERROR %s\n' "$1"; exit 5; }

[ -n "$expected" ] || fail "missing expected-sha arg"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not inside a git worktree"

sha=$(git rev-parse --verify "${expected}^{commit}" 2>/dev/null) || fail "unresolvable sha $expected"
head=$(git rev-parse HEAD 2>/dev/null) || fail "HEAD unresolvable"

short(){ git rev-parse --short "$1" 2>/dev/null || printf '%s' "$1"; }

if [ "$head" = "$sha" ]; then
  printf 'FFCHECK: OK %s\n' "$(short "$sha")"
  exit 0
fi

if git merge-base --is-ancestor HEAD "$sha"; then
  git merge --ff-only "$sha" >/dev/null 2>&1 || fail "ff-only merge failed"
  printf 'FFCHECK: OK %s\n' "$(short "$sha")"
  exit 0
fi

printf 'FFCHECK: DIVERGED head=%s expected=%s\n' "$(short "$head")" "$(short "$sha")"
exit 2
