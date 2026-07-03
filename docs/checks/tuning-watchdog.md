# Checks: tuning-watchdog

Purpose: verify the done-signal fix — done = terminal `STATUS:` line, not
report existence.
Spec (fix contract): `docs/spec/loop-tuning.md` Interface contract.
Files owned: `skills/architect/watchdog.ps1`, `skills/architect/watchdog.sh`.

Executor: PowerShell primary; native git fine. The sh cannot execute in
this sandbox (MSYS death): static checks only for sh; the orchestrator runs
its functional pass at composite. Fixtures under `.architect/tmp/twfix/`.
Orchestrator bookkeeping commits exempt from touch-set checks.

## TW1 — contract markers unchanged

- `(Select-String -Path skills/architect/watchdog.ps1 -Pattern 'WATCHDOG: (ALL_DONE|INTEGRATED|STALL|REPEAT)').Count` → ≥4
- `(Select-String -Path skills/architect/watchdog.sh -Pattern 'WATCHDOG: (ALL_DONE|INTEGRATED|STALL|REPEAT)').Count` → ≥4
- Both scripts reference `STATUS:` (the new done test) → Select-String count ≥1 each.

## TW2 — ps1 parses

In-session PowerShell (never nested `powershell -Command`):
```powershell
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'skills/architect/watchdog.ps1').Path, [ref]$null, [ref]$e) | Out-Null
if ($e.Count -eq 0) { 'TW2_OK' } else { $e }
```
PASS: `TW2_OK`.

## TW3 — functional: finished report → ALL_DONE

Fixture: `twfix/done/` with events file (any content) and a report whose
last non-blank line is `STATUS: COMPLETE`; config `sweep_sec:1,
stall_after_min:0.05`. Run watchdog.ps1.
PASS: exit 0; `WATCHDOG: ALL_DONE`; evidence line has path + bytes.

## TW4 — functional: mid-write report is NOT done

Fixture: `twfix/midwrite/` with a static events file, a report containing
prose but NO line starting `STATUS:`, worktree path matching no process,
same tiny thresholds. Run watchdog.ps1.
PASS: exit `3` (`WATCHDOG: STALL` — the job kept sweeping and hit the
no-growth rule) and NO `ALL_DONE` anywhere in the output.

## TW5 — regressions: STALL and INTEGRATED unchanged

- Re-run the prior STALL fixture shape (no report at all, static events, no
  process) → exit 3, `WATCHDOG: STALL`.
- Nonexistent events file AND worktree → exit 2, `WATCHDOG: INTEGRATED`.

## TW6 — line budget and never-act guard

- `(Get-Content skills/architect/watchdog.ps1 | Where-Object { $_.Trim() }).Count` → ≤ 95; same for `.sh` → ≤ 95
- `Select-String -Path skills/architect/watchdog.ps1,skills/architect/watchdog.sh -Pattern 'Stop-Process|taskkill|Remove-Item|rm -|git (add|commit|push)'` → no matches
