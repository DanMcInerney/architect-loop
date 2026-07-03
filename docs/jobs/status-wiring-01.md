# status-wiring-01

## Phase 0

| Item | Raw evidence |
|---|---|
| First action HEAD | `git log -1 --oneline` -> `eacc00e re-freeze: stress-test amendments (degraded-mode phase honesty, REPORTED glyph, exact SS3 fixtures, fresh uv cache, PS-native size count)` |
| First action check file | `Test-Path -LiteralPath 'docs/checks/status-wiring.md'` -> `True` |
| Files checked before edit | `docs/spec/status-tree.md`; `docs/checks/status-wiring.md`; `skills/architect/SKILL.md`; `skills/architect/dispatch.md` |
| Pre-edit size guard | `TOTAL 789` |
| Plan | Add one Factory Loop status-request bullet to `skills/architect/SKILL.md`; add one `## Status display` note to `skills/architect/dispatch.md`; do not edit `docs/checks/**`; run SW1, SW2, SW3 sequentially. |
| Disagreements | None blocking. The report path `docs/jobs/status-wiring-01.md` is outside implementation MAY TOUCH, but the issue separately requires this report path. |
| Issue mirror | `MIRROR: ORCHESTRATOR` |

## SW1

Command:
```powershell
git grep -ci "status.ps1" -- skills/architect/SKILL.md
```
Output:
```text
skills/architect/SKILL.md:1
```

Command:
```powershell
git grep -c "verbatim" -- skills/architect/SKILL.md
```
Output:
```text
skills/architect/SKILL.md:1
```

Command:
```powershell
git grep -c "## Status display" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Command:
```powershell
git grep -ci "status.sh" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

## SW2

Command:
```powershell
$files='skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'
$total=($files | ForEach-Object { (Get-Content $_ | Where-Object { $_.Trim() }).Count } | Measure-Object -Sum).Sum
"TOTAL $total"
```
Output:
```text
TOTAL 794
```

## SW3

Command:
```powershell
git diff --name-only eacc00e..HEAD
```
Output:
```text
```

Command:
```powershell
git grep -c "## Factory Loop\|### 4. Factory Loop" -- skills/architect/SKILL.md
```
Output:
```text
skills/architect/SKILL.md:1
```

Pointer command:
```powershell
git grep -c "## Model alias table" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Pointer command:
```powershell
git grep -c "## Issue conventions" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Pointer command:
```powershell
git grep -c "## Monitor dispatch" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Pointer command:
```powershell
git grep -c "## Respawn-with-answer template" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Final command:
```powershell
git status --short
```
Output:
```text
 M skills/architect/SKILL.md
 M skills/architect/dispatch.md
?? docs/jobs/status-wiring-01.md
```

STATUS: COMPLETE
