# Checkrun: trigger-evals-01-checkrun
generated: 2026-07-05T01:57:57.1806675Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-trigger-evals-01.json
check_file: docs/checks/trigger-evals.md  freeze_sha: a3d7a231751988577b2e4ec763c7e2674f9d0c06
Executor: PowerShell (Windows PowerShell 5.1, native git). PowerShell is the
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=a3d7a231751988577b2e4ec763c7e2674f9d0c06
changed_files: 0 listed below; docs_checks_touched=false

## Runnable checks line 21
$ git check-ignore -q docs/evals/trigger-prompts.md; $LASTEXITCODE
exit: 1  ms: 471  bytes: 3
1

## Runnable checks line 22
$ (Get-Content docs/evals/trigger-prompts.md | Select-String '^- PROMPT:').Count -ge 20
exit: 0  ms: 465  bytes: 6
True

## Runnable checks line 23
$ (Get-Content docs/evals/trigger-prompts.md | Select-String '^\s+SKILL: architect$').Count -ge 10
exit: 0  ms: 454  bytes: 6
True

## Runnable checks line 24
$ (Get-Content docs/evals/trigger-prompts.md | Select-String '^\s+SKILL: architect-research$').Count -ge 10
exit: 0  ms: 499  bytes: 6
True

## Runnable checks line 25
$ (Get-Content docs/evals/trigger-prompts.md | Select-String '^\s+EXPECT: no-trigger').Count -ge 4
exit: 0  ms: 435  bytes: 6
True

## Runnable checks line 26
$ $f=Get-Content docs/evals/trigger-prompts.md; (($f | Select-String '^- PROMPT:').Count -eq ($f | Select-String '^\s+EXPECT:').Count) -and (($f | Select-String '^- PROMPT:').Count -eq ($f | Select-String '^\s+SKILL:').Count)
exit: 0  ms: 455  bytes: 6
True

## Runnable checks line 27
$ Test-Path skills/architect/trigger-eval.ps1
exit: 0  ms: 482  bytes: 6
True

## Runnable checks line 28
$ Test-Path skills/architect/trigger-eval.sh
exit: 0  ms: 445  bytes: 6
True
