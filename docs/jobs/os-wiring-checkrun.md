# Checkrun: os-wiring-checkrun
generated: 2026-07-04T20:56:58.5922481Z  runner: ps1  config: C:/Users/danhm/tools/architect-loop/.architect/checkrun-os-wiring.json
check_file: docs/checks/os-wiring.md  freeze_sha: 4ebe337a65e0fe616eb4d3310a307c8eba3c8179
Executor: powershell; native `git.exe`. Orchestrator bookkeeping commits
executor_config: powershell
integrity: check_file_matches_freeze=true head=3b99504cbfdb4f4cebea8533d2e00a975def8b87
changed_files: 4 listed below; docs_checks_touched=false
docs/jobs/os-wiring-01.md
skills/architect/SKILL.md
skills/architect/dispatch.md
skills/architect/loop.md

## WI1 — dispatch.md section and contracts line 13
$ git grep -c "## Preflight and postflight dispatch" -- skills/architect/dispatch.md
exit: 1  ms: 170  bytes: 24
fatal: no pattern given

## WI1 — dispatch.md section and contracts line 14
$ git grep -c "PREFLIGHT: OK" -- skills/architect/dispatch.md
exit: 128  ms: 164  bytes: 38
fatal: unable to resolve revision: OK

## WI1 — dispatch.md section and contracts line 15
$ git grep -c "POSTFLIGHT: VIOLATION" -- skills/architect/dispatch.md
exit: 128  ms: 171  bytes: 45
fatal: unable to resolve revision: VIOLATION

## WI1 — dispatch.md section and contracts line 16
$ git grep -c "POSTFLIGHT: CONFLICT" -- skills/architect/dispatch.md
exit: 128  ms: 158  bytes: 44
fatal: unable to resolve revision: CONFLICT

## WI1 — dispatch.md section and contracts line 17
$ git grep -c "require_files" -- skills/architect/dispatch.md
exit: 0  ms: 163  bytes: 31
skills/architect/dispatch.md:2

## WI1 — dispatch.md section and contracts line 18
$ git grep -c "merge_message" -- skills/architect/dispatch.md
exit: 0  ms: 178  bytes: 31
skills/architect/dispatch.md:1

## WI1 — dispatch.md section and contracts line 19
$ git grep -c "factory_branch" -- skills/architect/dispatch.md
exit: 0  ms: 173  bytes: 31
skills/architect/dispatch.md:1

## WI2 — typed exits: 3 = decomposition failure, 2 = FAIL evidence, 5 = fallback line 23
$ git grep -c "exit 3" -- skills/architect/dispatch.md
exit: 128  ms: 174  bytes: 37
fatal: unable to resolve revision: 3

## WI2 — typed exits: 3 = decomposition failure, 2 = FAIL evidence, 5 = fallback line 24
$ git grep -c "decomposition failure" -- skills/architect/dispatch.md
exit: 128  ms: 165  bytes: 43
fatal: unable to resolve revision: failure

## WI2 — typed exits: 3 = decomposition failure, 2 = FAIL evidence, 5 = fallback line 25
$ git grep -c "POSTFLIGHT: ERROR" -- skills/architect/dispatch.md
exit: 128  ms: 169  bytes: 41
fatal: unable to resolve revision: ERROR

## WI3 — loop.md and SKILL.md name the scripts line 29
$ git grep -c "postflight" -- skills/architect/loop.md
exit: 0  ms: 172  bytes: 27
skills/architect/loop.md:3

## WI3 — loop.md and SKILL.md name the scripts line 30
$ git grep -c "preflight.ps1" -- skills/architect/SKILL.md
exit: 0  ms: 165  bytes: 28
skills/architect/SKILL.md:1

## WI3 — loop.md and SKILL.md name the scripts line 31
$ git grep -c "postflight" -- skills/architect/SKILL.md
exit: 0  ms: 170  bytes: 28
skills/architect/SKILL.md:1

## WI4 — size guards (non-blank lines) line 35
$ (Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() }).Count
exit: 0  ms: 173  bytes: 5
209

## WI4 — size guards (non-blank lines) line 36
$ (Get-Content skills/architect/loop.md | Where-Object { $_.Trim() }).Count
exit: 0  ms: 175  bytes: 5
100

## WI4 — size guards (non-blank lines) line 37
$ (Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() }).Count
exit: 0  ms: 184  bytes: 5
540
