# Checkrun: loop-hygiene-xplat-checkrun
generated: 2026-07-04T23:45:13.3354390Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-xplat.json
check_file: docs/checks/loop-hygiene-xplat.md  freeze_sha: cbfb4734d30557c5ebb72b91239024e6e69a946c
Executor: bash
executor_config: bash
integrity: check_file_matches_freeze=true head=da73b972ba7821df5a97cb3f42f34a31f1279132
changed_files: 6 listed below; docs_checks_touched=false
docs/jobs/loop-hygiene-xplat-01.md
skills/architect/check-runner.sh
skills/architect/postflight.sh
skills/architect/status.ps1
skills/architect/watchdog.ps1
skills/architect/watchdog.sh

## (root) line 18
$ bash -n skills/architect/status.sh
exit: 0  ms: 154  bytes: 0

## (root) line 19
$ bash -n skills/architect/watchdog.sh
exit: 0  ms: 119  bytes: 0

## (root) line 20
$ bash -n skills/architect/check-runner.sh
exit: 0  ms: 116  bytes: 0

## (root) line 21
$ bash -n skills/architect/preflight.sh
exit: 0  ms: 111  bytes: 0

## (root) line 22
$ bash -n skills/architect/postflight.sh
exit: 0  ms: 116  bytes: 0

## (root) line 23
$ bash -n install.sh
exit: 0  ms: 108  bytes: 0

## (root) line 24
$ grep -lE "mapfile|readarray|declare -A" skills/architect/status.sh skills/architect/watchdog.sh skills/architect/check-runner.sh skills/architect/preflight.sh skills/architect/postflight.sh install.sh
exit: 1  ms: 138  bytes: 0

## (root) line 25
$ grep -lE "\\$\\{[A-Za-z_][A-Za-z0-9_]*(\\^\\^|,,)[^}]*\\}" skills/architect/status.sh skills/architect/watchdog.sh skills/architect/check-runner.sh skills/architect/preflight.sh skills/architect/postflight.sh install.sh
exit: 1  ms: 104  bytes: 0

## (root) line 26
$ powershell -NoProfile -Command '$bad=0; Get-ChildItem "skills/architect/*.ps1","install.ps1" | ForEach-Object { $t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$t,[ref]$e); if ($e.Count) { Write-Output ($_.Name + " PARSE_ERRORS"); $bad=1 } }; if ($bad) { exit 1 }; Write-Output "PS_PARSE_OK"'
exit: 127  ms: 153  bytes: 49
/bin/bash: line 1: powershell: command not found

## (root) line 27
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run --no-project python tests/validate_skills.py
exit: 127  ms: 152  bytes: 41
/bin/bash: line 1: uv: command not found

## (root) line 28
$ git grep -c "PREFLIGHT: OK" -- skills/architect/preflight.sh skills/architect/preflight.ps1
exit: 128  ms: 112  bytes: 178
fatal: not a git repository: /mnt/c/Users/danhm/tools/architect-loop/.architect/wt/loop-hygiene-xplat-01/C:/Users/danhm/tools/architect-loop/.git/worktrees/loop-hygiene-xplat-01

## (root) line 29
$ git grep -c "CHECKRUN: ERROR" -- skills/architect/check-runner.sh skills/architect/check-runner.ps1
exit: 128  ms: 115  bytes: 178
fatal: not a git repository: /mnt/c/Users/danhm/tools/architect-loop/.architect/wt/loop-hygiene-xplat-01/C:/Users/danhm/tools/architect-loop/.git/worktrees/loop-hygiene-xplat-01
