# hardening-watchdog-01

MIRROR: ORCHESTRATOR

## Phase 0

| Item | Result |
|---|---|
| Job | hardening-watchdog-01 |
| Freeze commit required | 27b1fc2 |
| Report path | docs/jobs/hardening-watchdog-01.md |

```powershell
git log -1 --oneline
```

```text
27b1fc2 re-freeze: stress-test amendments (WA2 quoting, DB3 scope exclusion, DD4 base-commit form, D scope consistency)
```

```powershell
Test-Path -LiteralPath 'docs/checks/hardening-watchdog.md'; if (Test-Path -LiteralPath 'docs/checks/hardening-watchdog.md') { Get-Item -LiteralPath 'docs/checks/hardening-watchdog.md' | Select-Object FullName,Length }
```

```text
True

FullName                                                                                            Length
--------                                                                                            ------
C:\Users\danhm\architect-loop\.architect\wt\hardening-watchdog-01\docs\checks\hardening-watchdog.md   4058
```

## Plan

| Step | Files |
|---|---|
| Read binding spec and frozen checks | docs/spec/ops-hardening.md; docs/checks/hardening-watchdog.md |
| Implement watchdog.ps1 | skills/architect/watchdog.ps1 |
| Implement watchdog.sh | skills/architect/watchdog.sh |
| Add validator contract checks | tests/validate_skills.py |
| Run WA1-WA7 sequentially | docs/checks/hardening-watchdog.md |
| Write report | docs/jobs/hardening-watchdog-01.md |

## Disagreements

| Source | File | Line/Output | Disagreement |
|---|---|---|---|
| Skill instruction | C:\Users\danhm\.agents\skills\implement\SKILL.md | `Commit your work to the current branch.` | Job instruction says `Do NOT commit and do NOT run git add / git mv`; no commit run. |
| Issue instruction | docs/spec/ops-hardening.md; docs/checks/hardening-watchdog.md; docs/research/factory-hardening-evidence.md | Interface contract and WA1-WA7 checked | None blocking. |

## Implementation Counts

```powershell
(Get-Content -LiteralPath 'skills/architect/watchdog.ps1').Count; (Get-Content -LiteralPath 'skills/architect/watchdog.sh').Count
```

```text
71
74
```

## WA1

```powershell
Test-Path skills/architect/watchdog.ps1; Test-Path skills/architect/watchdog.sh
```

```text
True
True
```

```powershell
(Select-String -Path skills/architect/watchdog.ps1 -Pattern 'WATCHDOG: (ALL_DONE|INTEGRATED|STALL|REPEAT)').Count
```

```text
4
```

```powershell
(Select-String -Path skills/architect/watchdog.sh -Pattern 'WATCHDOG: (ALL_DONE|INTEGRATED|STALL|REPEAT)').Count
```

```text
4
```

```powershell
(Get-Content skills/architect/watchdog.sh -TotalCount 1)
```

```text
#!/usr/bin/env bash
```

## WA2

```powershell
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'skills/architect/watchdog.ps1').Path, [ref]$null, [ref]$e) | Out-Null
if ($e.Count -eq 0) { 'WA2_OK' } else { $e }
```

```text
WA2_OK
```

## WA3

```powershell
New-Item -ItemType Directory -Force -Path '.architect/tmp/wdtest' | Out-Null
Set-Content -LiteralPath '.architect/tmp/wdtest/report1.md' -Value 'done'
Set-Content -LiteralPath '.architect/tmp/wdtest/events1.jsonl' -Value '{"event":"x"}'
Set-Content -LiteralPath '.architect/tmp/wdtest/cfg-done.json' -Value '{"sweep_sec":1,"stall_after_min":0.05,"jobs":[{"id":"t1","events_file":".architect/tmp/wdtest/events1.jsonl","report_path":".architect/tmp/wdtest/report1.md","worktree":".architect/tmp/wdtest","duration_hint_min":0}]}'
& powershell -NoProfile -File 'skills/architect/watchdog.ps1' -Config '.architect/tmp/wdtest/cfg-done.json'
"EXIT=$LASTEXITCODE"
```

```text
WATCHDOG: ALL_DONE
t1 .architect/tmp/wdtest/report1.md 6 bytes
EXIT=0
```

## WA4

```powershell
New-Item -ItemType Directory -Force -Path '.architect/tmp/wdtest' | Out-Null
Set-Content -LiteralPath '.architect/tmp/wdtest/events2.jsonl' -Value '{"event":"static"}'
Remove-Item -LiteralPath '.architect/tmp/wdtest/report2.md' -ErrorAction SilentlyContinue
Set-Content -LiteralPath '.architect/tmp/wdtest/cfg-stall.json' -Value '{"sweep_sec":1,"stall_after_min":0.05,"jobs":[{"id":"t1","events_file":".architect/tmp/wdtest/events2.jsonl","report_path":".architect/tmp/wdtest/report2.md","worktree":".architect/tmp/wdtest/nomatch-zz9","duration_hint_min":0}]}'
& powershell -NoProfile -File 'skills/architect/watchdog.ps1' -Config '.architect/tmp/wdtest/cfg-stall.json'
"EXIT=$LASTEXITCODE"
```

```text
WATCHDOG: STALL t1 minutes_since_growth=0.053 cpu_delta=0
{"event":"static"}

EXIT=3
```

## WA5

```powershell
New-Item -ItemType Directory -Force -Path '.architect/tmp/wdtest' | Out-Null
Remove-Item -LiteralPath '.architect/tmp/wdtest/events-gone.jsonl' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath '.architect/tmp/wdtest/worktree-gone' -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath '.architect/tmp/wdtest/report-gone.md' -ErrorAction SilentlyContinue
Set-Content -LiteralPath '.architect/tmp/wdtest/cfg-gone.json' -Value '{"sweep_sec":1,"stall_after_min":0.05,"jobs":[{"id":"t1","events_file":".architect/tmp/wdtest/events-gone.jsonl","report_path":".architect/tmp/wdtest/report-gone.md","worktree":".architect/tmp/wdtest/worktree-gone","duration_hint_min":0}]}'
& powershell -NoProfile -File 'skills/architect/watchdog.ps1' -Config '.architect/tmp/wdtest/cfg-gone.json'
"EXIT=$LASTEXITCODE"
```

```text
WATCHDOG: INTEGRATED t1
EXIT=2
```

## WA6

```powershell
(Select-String -Path tests/validate_skills.py -Pattern '"watchdog.ps1"').Count
```

```text
2
```

```powershell
(Select-String -Path tests/validate_skills.py -Pattern '"watchdog.sh"').Count
```

```text
2
```

```powershell
(Select-String -Path tests/validate_skills.py -Pattern 'check_watchdog_contract').Count
```

```text
2
```

```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('WA6_OK')"
```

```text
WA6_OK
```

## WA7

```powershell
Select-String -Path skills/architect/watchdog.ps1,skills/architect/watchdog.sh -Pattern 'Stop-Process|taskkill|kill |Remove-Item|rm -'
```

```text
```

## Extra Validator

```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python tests/validate_skills.py
```

```text
OK - 2 skills validated, v4 contracts clean
```

## Scope

```powershell
git status --short
```

```text
 M tests/validate_skills.py
?? docs/jobs/
?? skills/architect/watchdog.ps1
?? skills/architect/watchdog.sh
```

```powershell
git diff -- docs/checks/hardening-watchdog.md
```

```text
```

STATUS: COMPLETE
