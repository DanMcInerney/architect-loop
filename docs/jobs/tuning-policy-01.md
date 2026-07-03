# tuning-policy-01

## PHASE 0

Plan:
- Verify freeze input.
- Read `docs/checks/tuning-policy.md`, `docs/spec/loop-tuning.md`, `skills/architect/SKILL.md`, `skills/architect/loop.md`, `skills/architect/dispatch.md`.
- Edit only `skills/architect/SKILL.md` and `skills/architect/loop.md`.
- Run every check in `docs/checks/tuning-policy.md` sequentially.
- Write `docs/jobs/tuning-policy-01.md`.

Disagreements:
- None.

Checked before concluding sound:
- `docs/spec/loop-tuning.md` Approval record and Interface contract.
- `docs/checks/tuning-policy.md`.
- `skills/architect/SKILL.md`.
- `skills/architect/loop.md`.
- `skills/architect/dispatch.md`.

MIRROR: ORCHESTRATOR

## Input Verification

Command:
```powershell
git log -1 --oneline
```
Output:
```text
6214c29 re-freeze: TW4b growing-report liveness check; concrete digest citation (stress-test amendments)
```

Command:
```powershell
Test-Path -LiteralPath docs/checks/tuning-policy.md
```
Output:
```text
True
```

## TP1

Command:
```powershell
git grep -ciE "5 minutes|five minutes|~5 min" -- skills/architect/SKILL.md
```
Output:
```text
skills/architect/SKILL.md:1
```

Command:
```powershell
git grep -ci "best judgment\|best judgement" -- skills/architect/SKILL.md
```
Output:
```text
skills/architect/SKILL.md:1
```

Command:
```powershell
git grep -ci "AWAITING APPROVAL" -- skills/architect/SKILL.md
```
Exit code: 1
Output:
```text
```

Command:
```powershell
git grep -ciE "7 days|7-day" -- skills/architect/SKILL.md
```
Exit code: 1
Output:
```text
```

Command:
```powershell
$i=0; Get-Content -LiteralPath skills/architect/SKILL.md | ForEach-Object { $i++; if($i -ge 128 -and $i -le 133){ '{0}: {1}' -f $i,$_ } }
```
Output:
```text
128: If the human is absent, ask in-session and wait about 5 minutes: use the
129: harness ~60s prompt, schedule one ~4-minute recheck, then rule with the
130: orchestrator's best judgment, record the ruling and reasoning on the tracking
131: issue for after-the-fact veto, and continue. This applies to every human question
132: in the loop, including spec approval, oddity escalations, and rail rulings. For irreversible or destructive choices, silence resolves to the
133: non-destructive path; `docs/STOP` remains absolute.
```

## TP2

Command:
```powershell
git grep -ci "research.md" -- skills/architect/SKILL.md
```
Output:
```text
skills/architect/SKILL.md:2
```

Command:
```powershell
$i=0; Get-Content -LiteralPath skills/architect/SKILL.md | ForEach-Object { $i++; if($i -ge 165 -and $i -le 174){ '{0}: {1}' -f $i,$_ } }
```
Output:
```text
165: - Oddity rule: when reality resists the plan, classify before dispatch. A
166:   local wart gets a local patch and issue note. A recurring variation gets a
167:   structural issue that blocks the behavioral issue. One adapter is a
168:   hypothetical seam; two is real. Three failed fixes on the same point means
169:   stop and question the architecture. Re-planning is orchestrator-owned: on
170:   an oddity or failure diagnosis the orchestrator may fan out researcher agents
171:   using `research.md` inline mechanics to inform the new plan, then updates the
172:   spec, issue, and checks in git and the tracker, then respawns a fresh
173:   builder; builders never re-plan.
174: - Structural and behavioral changes are separate issues with a blocking edge.
```

## TP3

Command:
```powershell
git grep -ci "concurrent" -- skills/architect/loop.md
```
Output:
```text
skills/architect/loop.md:1
```

Command:
```powershell
$i=0; Get-Content -LiteralPath skills/architect/loop.md | ForEach-Object { $i++; if($i -ge 3 -and $i -le 8){ '{0}: {1}' -f $i,$_ } }
```
Output:
```text
3: The loop is one orchestrator session that runs the factory to completion after
4: the spec approval approves the issue plan. GitHub issues carry coordination
5: state; git carries specs and frozen checks. The orchestrator dispatches the
6: ready issues, sleeps, and wakes only on an event.
7: Parallel rules: judges dispatch immediately and run concurrently for every DONE, never queued behind another judgment; the ready-issue frontier recomputes on EVERY merge, not at wave boundaries; independent orchestrator bookkeeping batches into parallel calls; merges, synthesis, and the stress-test stay serial by design.
8: 
```

Command:
```powershell
$i=0; Get-Content -LiteralPath skills/architect/loop.md | ForEach-Object { $i++; if($i -ge 76 -and $i -le 84){ '{0}: {1}' -f $i,$_ } }
```
Output:
```text
76: ## Failure ladder
77: 
78: First FAIL on an issue: the orchestrator diagnoses from the judge's evidence (not
79: the full diff), may fan out researcher agents to inform the diagnosis, fixes
80: the input â€” issue text, missing context, or a forbidden-pattern note â€” and
81: respawns a fresh builder job at the same tier.
82: The tier is set once, at decomposition (config plus dispatch rules), and
83: never changes because a job failed; a failure is a spec or context problem
84: the orchestrator fixes, never a signal to move the tier. Second FAIL on the same
```

## TP4

Command:
```powershell
$files='skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'
$total=($files | ForEach-Object { (Get-Content $_ | Where-Object { $_.Trim() }).Count } | Measure-Object -Sum).Sum
"TOTAL $total"
```
Output:
```text
TOTAL 800
```

## TP5

Command:
```powershell
git grep -c "^## Model alias table" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Command:
```powershell
git grep -c "^## Issue conventions" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Command:
```powershell
git grep -c "^## Monitor dispatch" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Command:
```powershell
git grep -c "^## Respawn-with-answer template" -- skills/architect/dispatch.md
```
Output:
```text
skills/architect/dispatch.md:1
```

Command:
```powershell
git grep -c "^## Factory block procedure" -- skills/architect/loop.md
```
Output:
```text
skills/architect/loop.md:1
```

Command:
```powershell
git grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" -- skills/architect/SKILL.md skills/architect/loop.md
```
Exit code: 1
Output:
```text
```

Command:
```powershell
git diff -- docs/checks
```
Output:
```text
```

Command:
```powershell
git status --short
```
Output:
```text
 M skills/architect/SKILL.md
 M skills/architect/loop.md
?? docs/jobs/tuning-policy-01.md
```

STATUS: COMPLETE
