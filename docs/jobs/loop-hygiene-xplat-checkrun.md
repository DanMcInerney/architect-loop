# Checkrun: loop-hygiene-xplat-checkrun
generated: 2026-07-04T23:55:34.4051085Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-xplat.json
check_file: docs/checks/loop-hygiene-xplat.md  freeze_sha: cbfb4734d30557c5ebb72b91239024e6e69a946c
Executor: bash
executor_config: bash
executor_resolved: C:\Program Files\Git\bin\bash.exe
integrity: check_file_matches_freeze=true head=24edb715f14fb4b979c0765e942f1bec222806c1
changed_files: 7 listed below; docs_checks_touched=false
docs/jobs/loop-hygiene-xplat-01.md
skills/architect/check-runner.ps1
skills/architect/check-runner.sh
skills/architect/postflight.sh
skills/architect/status.ps1
skills/architect/watchdog.ps1
skills/architect/watchdog.sh

## (root) line 18
$ bash -n skills/architect/status.sh
exit: 0  ms: 73  bytes: 0

## (root) line 19
$ bash -n skills/architect/watchdog.sh
exit: 0  ms: 77  bytes: 0

## (root) line 20
$ bash -n skills/architect/check-runner.sh
exit: 0  ms: 71  bytes: 0

## (root) line 21
$ bash -n skills/architect/preflight.sh
exit: 0  ms: 63  bytes: 0

## (root) line 22
$ bash -n skills/architect/postflight.sh
exit: 0  ms: 70  bytes: 0

## (root) line 23
$ bash -n install.sh
exit: 0  ms: 62  bytes: 0

## (root) line 24
$ grep -lE "mapfile|readarray|declare -A" skills/architect/status.sh skills/architect/watchdog.sh skills/architect/check-runner.sh skills/architect/preflight.sh skills/architect/postflight.sh install.sh
exit: 1  ms: 56  bytes: 0

## (root) line 25
$ grep -lE "\\$\\{[A-Za-z_][A-Za-z0-9_]*(\\^\\^|,,)[^}]*\\}" skills/architect/status.sh skills/architect/watchdog.sh skills/architect/check-runner.sh skills/architect/preflight.sh skills/architect/postflight.sh install.sh
exit: 1  ms: 59  bytes: 0

## (root) line 26
$ powershell -NoProfile -Command '$bad=0; Get-ChildItem "skills/architect/*.ps1","install.ps1" | ForEach-Object { $t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$t,[ref]$e); if ($e.Count) { Write-Output ($_.Name + " PARSE_ERRORS"); $bad=1 } }; if ($bad) { exit 1 }; Write-Output "PS_PARSE_OK"'
exit: 0  ms: 279  bytes: 13
PS_PARSE_OK

## (root) line 27
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run --no-project python tests/validate_skills.py
exit: 0  ms: 148  bytes: 45
OK - 2 skills validated, v4 contracts clean

## (root) line 28
$ git grep -c "PREFLIGHT: OK" -- skills/architect/preflight.sh skills/architect/preflight.ps1
exit: 0  ms: 67  bytes: 65
skills/architect/preflight.ps1:1
skills/architect/preflight.sh:1

## (root) line 29
$ git grep -c "CHECKRUN: ERROR" -- skills/architect/check-runner.sh skills/architect/check-runner.ps1
exit: 0  ms: 96  bytes: 71
skills/architect/check-runner.ps1:2
skills/architect/check-runner.sh:1
