# Checkrun: skill-guards-01-checkrun
generated: 2026-07-05T01:57:17.6381086Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-skill-guards-01.json
check_file: docs/checks/skill-guards.md  freeze_sha: a3d7a231751988577b2e4ec763c7e2674f9d0c06
Executor: PowerShell (Windows PowerShell 5.1, native git). PowerShell is the
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=4fd97d18994438846481f562189bc40a78faacca
changed_files: 7 listed below; docs_checks_touched=false
docs/jobs/skill-text-01-checkrun.md
docs/jobs/skill-text-01.md
skills/architect-research/SKILL.md
skills/architect-research/tactics.md
skills/architect/SKILL.md
skills/architect/dispatch.md
skills/architect/loop.md

## Runnable checks line 19
$ uv run --no-project python tests/validate_skills.py; $LASTEXITCODE
exit: 0  ms: 785  bytes: 48
OK - 2 skills validated, v4 contracts clean
0

## Runnable checks line 20
$ (Get-Content tests/validate_skills.py | Select-String 'research\.md').Count -ge 2
exit: 0  ms: 481  bytes: 6
True

## Runnable checks line 21
$ (Get-Content tests/validate_skills.py | Select-String 'tracker\.md').Count -ge 5
exit: 0  ms: 464  bytes: 6
True

## Runnable checks line 22
$ (Get-Content tests/validate_skills.py | Select-String '1100').Count -ge 1
exit: 0  ms: 456  bytes: 6
True

## Runnable checks line 23
$ (Get-Content tests/validate_skills.py | Select-String 'tactics\.md').Count -ge 2
exit: 0  ms: 482  bytes: 6
True

## Runnable checks line 24
$ (Get-Content tests/validate_skills.py | Select-String '5000|5_000').Count -ge 1
exit: 0  ms: 460  bytes: 6
True

## Runnable checks line 25
$ (Get-Content DESIGN.md | Select-String '800-non-blank').Count
exit: 0  ms: 511  bytes: 3
0

## Runnable checks line 26
$ (Get-Content tests/validate_skills.py | Select-String '## Contents').Count -ge 1
exit: 0  ms: 534  bytes: 6
True
