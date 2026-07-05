# Checkrun: harden-checkrun
generated: 2026-07-05T19:17:12.4361317Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-harden.json
check_file: docs/checks/script-hardening/harden.md  freeze_sha: 10a73c755d0a9ef2dfca3b748bd34dc18c89eb94
Executor: PowerShell (primary; Windows codex sandbox kills Git Bash with
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=10a73c755d0a9ef2dfca3b748bd34dc18c89eb94
changed_files: 0 listed below; docs_checks_touched=false

## (root) line 23
$ uv run python tests/validate_skills.py
exit: 0  ms: 3922  bytes: 45
OK - 2 skills validated, v4 contracts clean

## (root) line 24
$ git grep -F -c "check_postflight_lane_fixture" -- tests/validate_skills.py
exit: 0  ms: 548  bytes: 27
tests/validate_skills.py:2

## (root) line 25
$ git grep -F -c "cleanup=deferred" -- skills/architect/postflight.ps1
exit: 0  ms: 448  bytes: 34
skills/architect/postflight.ps1:1

## (root) line 26
$ git grep -F -c "cleanup=deferred" -- skills/architect/postflight.sh
exit: 0  ms: 398  bytes: 33
skills/architect/postflight.sh:1

## (root) line 27
$ git grep -F -c "cleanup=deferred" -- skills/architect/dispatch.md
exit: 0  ms: 407  bytes: 31
skills/architect/dispatch.md:1

## (root) line 28
$ git grep -F -c "cleanup=deferred" -- docs/solutions/worktree-cleanup-locks.md
exit: 0  ms: 627  bytes: 43
docs/solutions/worktree-cleanup-locks.md:1

## (root) line 29
$ git grep -F -c "no commits beyond freeze" -- skills/architect/postflight.ps1 skills/architect/postflight.sh
exit: 0  ms: 397  bytes: 67
skills/architect/postflight.ps1:1
skills/architect/postflight.sh:1
