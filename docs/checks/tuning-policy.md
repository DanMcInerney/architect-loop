# Checks: tuning-policy

Purpose: verify the 5-minute autonomy policy, orchestrator-owned oddity
research, and parallel dispatch rules in the skill text.
Spec (fix contract): `docs/spec/loop-tuning.md` — Interface contract and
the verbatim approval record.
Files owned: `skills/architect/SKILL.md`, `skills/architect/loop.md`.

Executor: PowerShell primary; native git fine. Orchestrator bookkeeping
commits exempt from touch-set checks.

## TP1 — 5-minute policy present, park machinery gone

(`git grep -c` prints `<path>:<count>`)
- `git grep -ciE "5 minutes|five minutes|~5 min" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -ci "best judgment\|best judgement" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -ci "AWAITING APPROVAL" -- skills/architect/SKILL.md` → no output
- `git grep -ciE "7 days|7-day" -- skills/architect/SKILL.md` → no output
- The every-question extension sentence and the destructive carve-out are
  both present — quote each.

## TP2 — oddity re-planning ownership

- `git grep -ci "research.md" -- skills/architect/SKILL.md` → count ≥ 1
  in/near the oddity text — quote the amended oddity sentence(s) showing:
  orchestrator owns re-planning, may fan out researchers, updates
  spec/issue/checks, respawns a fresh builder; builders never re-plan.

## TP3 — parallel rules in loop.md

- `git grep -ci "concurrent" -- skills/architect/loop.md` → count ≥ 1
- Quote the lines covering: judges never queued; frontier recomputed on
  EVERY merge; merges/synthesis/stress-test stay serial.
- Failure ladder mentions the researcher fan-out option — quote it.

## TP4 — size guard (PS-native)

```powershell
$files='skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'
$total=($files | ForEach-Object { (Get-Content $_ | Where-Object { $_.Trim() }).Count } | Measure-Object -Sum).Sum
"TOTAL $total"
```
PASS: TOTAL ≤ 800.

## TP5 — no collateral damage

- Pointer integrity: every `dispatch.md section` / `loop.md section` pointer
  named in SKILL.md resolves — list each with heading grep count 1.
- `git grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" -- skills/architect/SKILL.md skills/architect/loop.md` → no output.
- Final `git status --short` shows only the two owned files + exempt report — paste.
