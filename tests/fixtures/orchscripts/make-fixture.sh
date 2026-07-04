#!/usr/bin/env bash
set -eu

tmp=".architect/tmp"
repo="$tmp/orchfix"
cfg_dir="$tmp/orchcfg"

rm -rf "$repo" "$cfg_dir"
rm -rf "$tmp"/orchfix-wt-*
mkdir -p "$repo" "$cfg_dir"

quiet_git(){ git -C "$repo" "$@" >/dev/null 2>&1; }

git init "$repo" >/dev/null 2>&1
quiet_git config user.name "Orch Fixture"
quiet_git config user.email "orch-fixture@example.invalid"
quiet_git config core.autocrlf false

write_file(){
  path=$1
  text=$2
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$text" > "$path"
}
write_config(){
  name=$1
  body=$2
  printf '%s\n' "$body" > "$cfg_dir/$name"
}

write_file "$repo/base.txt" "base"
quiet_git add base.txt
quiet_git commit -m "base"
quiet_git checkout -b factory/test

write_file "$repo/allowed/a.txt" "freeze allowed"
write_file "$repo/docs/checks/frozen.md" "frozen checks"
write_file "$repo/conflict.txt" "freeze conflict"
quiet_git add allowed/a.txt docs/checks/frozen.md conflict.txt
quiet_git commit -m "freeze"
freeze=$(git -C "$repo" rev-parse HEAD)

write_file "$repo/conflict.txt" "factory side"
quiet_git add conflict.txt
quiet_git commit -m "factory conflict setup"

quiet_git checkout -b job/clean "$freeze"
write_file "$repo/allowed/a.txt" "job clean"
quiet_git add allowed/a.txt
quiet_git commit -m "job clean"

quiet_git checkout -b job/violation "$freeze"
write_file "$repo/docs/checks/frozen.md" "job violation"
quiet_git add docs/checks/frozen.md
quiet_git commit -m "job violation"

quiet_git checkout -b job/conflict "$freeze"
write_file "$repo/conflict.txt" "job side"
quiet_git add conflict.txt
quiet_git commit -m "job conflict"
quiet_git checkout factory/test

repo_abs=$(cd "$repo" && pwd -P)
bad_sha="deadbeef00000000000000000000000000000000"

write_config pre-ok.json "{
  \"repo_root\": \"$repo_abs\",
  \"freeze_sha\": \"$freeze\",
  \"worktree\": \".architect/tmp/orchfix-wt-ok\",
  \"job_branch\": \"job/pre-ok\",
  \"require_files\": [\"docs/checks/frozen.md\"]
}"
write_config pre-badsha.json "{
  \"repo_root\": \"$repo_abs\",
  \"freeze_sha\": \"$bad_sha\",
  \"worktree\": \".architect/tmp/orchfix-wt-bad\",
  \"job_branch\": \"job/pre-bad\",
  \"require_files\": [\"docs/checks/frozen.md\"]
}"
write_config post-clean.json "{
  \"repo_root\": \"$repo_abs\",
  \"factory_branch\": \"factory/test\",
  \"job_branch\": \"job/clean\",
  \"freeze_sha\": \"$freeze\",
  \"may_touch\": [\"allowed/\"],
  \"exempt\": [\"docs/jobs/\"],
  \"merge_message\": \"merge job clean\",
  \"push\": false,
  \"remote\": \"origin\",
  \"worktree\": \"\"
}"
write_config post-violation.json "{
  \"repo_root\": \"$repo_abs\",
  \"factory_branch\": \"factory/test\",
  \"job_branch\": \"job/violation\",
  \"freeze_sha\": \"$freeze\",
  \"may_touch\": [\"allowed/\"],
  \"exempt\": [\"docs/jobs/\"],
  \"merge_message\": \"merge job violation\",
  \"push\": false,
  \"remote\": \"origin\",
  \"worktree\": \"\"
}"
write_config post-conflict.json "{
  \"repo_root\": \"$repo_abs\",
  \"factory_branch\": \"factory/test\",
  \"job_branch\": \"job/conflict\",
  \"freeze_sha\": \"$freeze\",
  \"may_touch\": [\"conflict.txt\", \"allowed/\"],
  \"exempt\": [\"docs/jobs/\"],
  \"merge_message\": \"merge job conflict\",
  \"push\": false,
  \"remote\": \"origin\",
  \"worktree\": \"\"
}"

exit 0
