#!/usr/bin/env bash
set -u

cfg=${1:-}
repo_root=
worktree_path=
job_branch=
worktree_existed=true
branch_existed=true

json_unescape(){ printf '%s' "$1" | sed 's/\\"/"/g; s#\\/#/#g; s/\\\\/\\/g'; }
json_string(){ sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\(.*\)\"[[:space:]]*,[[:space:]]*$/\1/p; s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\(.*\)\"[[:space:]]*$/\1/p" "$cfg" | sed -n '1p' | while IFS= read -r v; do json_unescape "$v"; done; }
json_array(){
  awk -v key="$1" '
    $0 ~ "\"" key "\"" { active=1; sub(/^.*\[/, "") }
    active {
      line=$0
      done=0
      if (line ~ /\]/) { sub(/\].*$/, "", line); done=1 }
      while (match(line, /"[^"]*"/)) {
        print substr(line, RSTART + 1, RLENGTH - 2)
        line=substr(line, RSTART + RLENGTH)
      }
      if (done) exit
    }
  ' "$cfg" | while IFS= read -r v; do json_unescape "$v"; printf '\n'; done
}
to_bash_path(){ case "$1" in [A-Za-z]:\\*) if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s' "$1"; fi;; *) printf '%s' "$1";; esac; }
abs_path(){ p=$(to_bash_path "$1"); case "$p" in /*) printf '%s' "$p";; *) printf '%s/%s' "$(pwd -P)" "$p";; esac; }
git_repo(){ git -C "$repo_root" "$@"; }
branch_exists(){ git_repo show-ref --verify --quiet "refs/heads/$1"; }
cleanup_created(){
  if [ -n "$repo_root" ] && [ -n "$worktree_path" ] && [ "$worktree_existed" = false ] && [ -e "$worktree_path" ]; then
    git_repo worktree remove --force "$worktree_path" >/dev/null 2>&1 || rm -rf "$worktree_path"
  fi
  if [ -n "$repo_root" ] && [ -n "$job_branch" ] && [ "$branch_existed" = false ] && branch_exists "$job_branch"; then
    git_repo branch -D "$job_branch" >/dev/null 2>&1 || :
  fi
}
fail(){ cleanup_created; printf 'PREFLIGHT: FAIL %s\n' "$1"; exit 5; }

[ -n "$cfg" ] && [ -r "$cfg" ] || fail "unreadable config"
repo_root=$(json_string repo_root)
freeze_sha=$(json_string freeze_sha)
worktree=$(json_string worktree)
job_branch=$(json_string job_branch)
[ -n "$repo_root" ] || fail "missing repo_root"
[ -n "$freeze_sha" ] || fail "missing freeze_sha"
[ -n "$worktree" ] || fail "missing worktree"
[ -n "$job_branch" ] || fail "missing job_branch"
repo_root=$(to_bash_path "$repo_root")
case "$repo_root" in /*) ;; *) fail "repo_root not absolute";; esac
[ -d "$repo_root" ] || fail "repo_root missing"
worktree_path=$(abs_path "$worktree")

git_repo cat-file -e "$freeze_sha^{commit}" >/dev/null 2>&1 || fail "freeze_sha not found"
[ -e "$worktree_path" ] && worktree_existed=true || worktree_existed=false
[ "$worktree_existed" = false ] || fail "worktree exists"
if branch_exists "$job_branch"; then branch_existed=true; else branch_existed=false; fi
[ "$branch_existed" = false ] || fail "job_branch exists"

git_repo worktree add -b "$job_branch" "$worktree_path" "$freeze_sha" >/dev/null 2>&1 || fail "worktree add failed"
head=$(git -C "$worktree_path" rev-parse HEAD 2>/dev/null) || fail "head verify failed"
[ "$head" = "$freeze_sha" ] || fail "head mismatch"

while IFS= read -r rel || [ -n "$rel" ]; do
  [ -n "$rel" ] || continue
  [ -e "$worktree_path/$rel" ] || fail "missing required file $rel"
done <<EOF
$(json_array require_files)
EOF

printf 'PREFLIGHT: OK worktree=%s head=%s\n' "$worktree_path" "$head"
exit 0
