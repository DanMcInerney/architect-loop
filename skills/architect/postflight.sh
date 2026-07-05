#!/usr/bin/env bash
set -u

cfg=${1:-}
repo_root=
tmp_files=()
tmp_dir=

json_unescape(){ printf '%s' "$1" | sed 's/\\"/"/g; s#\\/#/#g; s/\\\\/\\/g'; }
json_string(){ sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\(.*\)\"[[:space:]]*,[[:space:]]*$/\1/p; s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\(.*\)\"[[:space:]]*$/\1/p" "$cfg" | sed -n '1p' | while IFS= read -r v; do json_unescape "$v"; done; }
json_bool(){ sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\\(true\\|false\\)[[:space:]]*,[[:space:]]*$/\\1/p; s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\\(true\\|false\\)[[:space:]]*$/\\1/p" "$cfg" | sed -n '1p'; }
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
abs_path(){ p=$(to_bash_path "$1"); case "$p" in /*) printf '%s' "$p";; *) printf '%s/%s' "$repo_root" "$p";; esac; }
add_tmp(){ tmp_files[${#tmp_files[@]}]=$1; }
cleanup_tmp(){ for f in "${tmp_files[@]}"; do [ -n "$f" ] && rm -f "$f"; done; }
trap cleanup_tmp EXIT
make_tmp(){
  [ -n "$tmp_dir" ] || err "tmp unavailable"
  mktemp "$tmp_dir/$1.XXXXXX" 2>/dev/null || err "tmp unavailable"
}
git_repo(){ git -C "$repo_root" "$@"; }
in_merge(){ [ -n "$repo_root" ] && git_repo rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; }
abort_merge(){
  # Abort any in-progress merge before CONFLICT and ERROR exits after merge work starts.
  if in_merge; then git_repo merge --abort >/dev/null 2>&1 || :; fi
}
err(){ abort_merge; printf 'POSTFLIGHT: ERROR %s\n' "$1"; exit 5; }
rule_match(){
  path=$1
  rule=$2
  [ -n "$rule" ] || return 1
  # D4 trailing-slash entries are case-sensitive prefix matches against forward-slash paths.
  case "$rule" in
    */) case "$path" in "$rule"*) return 0;; *) return 1;; esac;;
    *'*'*|*'?'*|*'['*) case "$path" in $rule) return 0;; *) return 1;; esac;;
    *) [ "$path" = "$rule" ];;
  esac
}
is_allowed(){
  path=$1
  # docs/checks/ is always a violation, regardless of configured globs.
  case "$path" in docs/checks/*) return 1;; esac
  for rule in "${may_touch[@]}" "${exempt[@]}"; do
    if rule_match "$path" "$rule"; then return 0; fi
  done
  return 1
}

[ -n "$cfg" ] && [ -r "$cfg" ] || { printf 'POSTFLIGHT: ERROR unreadable config\n'; exit 5; }
repo_root=$(json_string repo_root)
factory_branch=$(json_string factory_branch)
job_branch=$(json_string job_branch)
freeze_sha=$(json_string freeze_sha)
merge_message=$(json_string merge_message)
remote=$(json_string remote)
worktree=$(json_string worktree)
push=$(json_bool push)
[ -n "$remote" ] || remote=origin
[ -n "$push" ] || push=false
may_touch=()
while IFS= read -r v || [ -n "$v" ]; do [ -n "$v" ] && may_touch+=("$v"); done <<EOF
$(json_array may_touch)
EOF
exempt=()
while IFS= read -r v || [ -n "$v" ]; do [ -n "$v" ] && exempt+=("$v"); done <<EOF
$(json_array exempt)
EOF
[ -n "$repo_root" ] && [ -n "$factory_branch" ] && [ -n "$job_branch" ] && [ -n "$freeze_sha" ] && [ -n "$merge_message" ] || { printf 'POSTFLIGHT: ERROR missing config\n'; exit 5; }
repo_root=$(to_bash_path "$repo_root")
case "$repo_root" in /*) ;; *) printf 'POSTFLIGHT: ERROR repo_root not absolute\n'; exit 5;; esac
[ -d "$repo_root" ] || { printf 'POSTFLIGHT: ERROR repo_root missing\n'; exit 5; }
tmp_dir="$repo_root/.architect/tmp/postflight"
mkdir -p "$tmp_dir" 2>/dev/null || err "tmp unavailable"

current=$(git_repo rev-parse --abbrev-ref HEAD 2>/dev/null) || err "current branch unavailable"
# Refuse to run off the configured factory branch before touch audit or merge.
if [ "$current" != "$factory_branch" ]; then printf 'POSTFLIGHT: ERROR off factory branch current=%s expected=%s\n' "$current" "$factory_branch"; exit 5; fi
if in_merge; then err "merge in progress"; fi
git_repo cat-file -e "$freeze_sha^{commit}" >/dev/null 2>&1 || err "freeze_sha not found"
git_repo show-ref --verify --quiet "refs/heads/$job_branch" || err "job_branch not found"

wt=
if [ -n "$worktree" ]; then
  wt=$(abs_path "$worktree")
  [ -d "$wt" ] || err "worktree missing"
  lane_status_tmp=$(make_tmp lane-status); add_tmp "$lane_status_tmp"
  git -C "$wt" status --porcelain > "$lane_status_tmp" || err "worktree status failed"
  if [ -s "$lane_status_tmp" ]; then
    git -C "$wt" add -A || err "lane add failed"
    git -C "$wt" commit -m "$merge_message (lane)" || err "lane commit failed"
  fi
fi

freeze_rev=$(git_repo rev-parse "$freeze_sha") || err "freeze rev unavailable"
job_rev=$(git_repo rev-parse "$job_branch") || err "job rev unavailable"
if [ "$job_rev" = "$freeze_rev" ]; then err "job branch has no commits beyond freeze"; fi

changed_tmp=$(make_tmp changed); add_tmp "$changed_tmp"
violations_tmp=$(make_tmp violations); add_tmp "$violations_tmp"
git_repo diff --name-only "$freeze_sha..$job_branch" > "$changed_tmp" || err "diff failed"
changed_count=0
while IFS= read -r path || [ -n "$path" ]; do
  [ -n "$path" ] || continue
  path=${path//\\//}
  changed_count=$((changed_count + 1))
  if ! is_allowed "$path"; then printf 'POSTFLIGHT: VIOLATION %s\n' "$path" >> "$violations_tmp"; fi
done < "$changed_tmp"
if [ -s "$violations_tmp" ]; then cat "$violations_tmp"; exit 2; fi

merge_tmp=$(make_tmp merge); add_tmp "$merge_tmp"
if ! git_repo merge --no-ff "$job_branch" -m "$merge_message" > "$merge_tmp" 2>&1; then
  conflicts_tmp=$(make_tmp conflicts); add_tmp "$conflicts_tmp"
  git_repo diff --name-only --diff-filter=U > "$conflicts_tmp" 2>/dev/null || :
  if [ -s "$conflicts_tmp" ]; then
    abort_merge
    printf 'POSTFLIGHT: CONFLICT\n'
    cat "$conflicts_tmp"
    exit 3
  fi
  err "merge failed"
fi

if [ "$push" = true ]; then git_repo push "$remote" "$factory_branch" >/dev/null 2>&1 || err "push failed"; fi
cleanup_deferred=false
cleanup_path=
if [ -n "$worktree" ]; then
  if [ -e "$wt" ]; then
    if ! git_repo worktree remove "$wt" >/dev/null 2>&1; then
      sleep 2
      if ! git_repo worktree remove "$wt" >/dev/null 2>&1; then
        if ! git_repo worktree remove --force "$wt" >/dev/null 2>&1; then
          cleanup_deferred=true
          cleanup_path=$wt
        fi
      fi
    fi
  fi
fi
if ! git_repo branch -d "$job_branch" >/dev/null 2>&1; then printf 'POSTFLIGHT: WARNING branch-delete %s\n' "$job_branch"; fi
merge_sha=$(git_repo rev-parse HEAD) || err "merge sha unavailable"
if [ "$cleanup_deferred" = true ]; then
  printf 'POSTFLIGHT: OK merge=%s changed=%s cleanup=deferred %s\n' "$merge_sha" "$changed_count" "$cleanup_path"
else
  printf 'POSTFLIGHT: OK merge=%s changed=%s\n' "$merge_sha" "$changed_count"
fi
exit 0
