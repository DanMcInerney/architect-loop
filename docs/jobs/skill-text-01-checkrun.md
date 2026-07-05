# Checkrun: skill-text-01-checkrun
generated: 2026-07-05T01:42:10.6637077Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-skill-text-01.json
check_file: docs/checks/skill-text.md  freeze_sha: a3d7a231751988577b2e4ec763c7e2674f9d0c06
Executor: PowerShell (Windows PowerShell 5.1, native git). PowerShell is the
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=a3d7a231751988577b2e4ec763c7e2674f9d0c06
changed_files: 0 listed below; docs_checks_touched=false

## Runnable checks line 20
$ $c=Get-Content skills/architect-research/SKILL.md; ($c[0..(($c | Select-String '^effort:')[0].LineNumber - 1)] -join ' ') -match 'scout|synthes|tactics library|verifies claims'
exit: 0  ms: 723  bytes: 7
False

## Runnable checks line 21
$ $c=Get-Content skills/architect-research/SKILL.md; ($c[0..(($c | Select-String '^effort:')[0].LineNumber - 1)] -join ' ') -match 'Use when'
exit: 0  ms: 523  bytes: 6
True

## Runnable checks line 22
$ $c=Get-Content skills/architect-research/SKILL.md; ($c[0..(($c | Select-String '^effort:')[0].LineNumber - 1)] -join ' ').Length -le 1088
exit: 0  ms: 497  bytes: 6
True

## Runnable checks line 23
$ (Get-Content skills/architect/dispatch.md -TotalCount 12 | Select-String '^## Contents').Count
exit: 0  ms: 467  bytes: 3
1

## Runnable checks line 24
$ (Get-Content skills/architect/loop.md -TotalCount 12 | Select-String '^## Contents').Count
exit: 0  ms: 247  bytes: 3
1

## Runnable checks line 25
$ (Get-Content skills/architect-research/tactics.md -TotalCount 12 | Select-String '^## Contents').Count
exit: 0  ms: 515  bytes: 3
1

## Runnable checks line 26
$ git grep -c 'docs/evals/trigger-prompts.md' -- skills/architect/SKILL.md
exit: 0  ms: 491  bytes: 28
skills/architect/SKILL.md:1

## Runnable checks line 27
$ (Get-Content skills/architect/SKILL.md | Select-String '^\d+\. \*\*').Count
exit: 0  ms: 508  bytes: 3
9
