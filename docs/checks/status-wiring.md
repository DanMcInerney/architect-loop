# Checks: status-wiring

Purpose: verify the skill wiring for the status tree under the size cap.
Spec (fix contract): `docs/spec/status-tree.md` — A4 cap is binding.
Files owned: `skills/architect/SKILL.md`, `skills/architect/dispatch.md`.

Executor: PowerShell primary; native `git.exe` fine. Orchestrator
bookkeeping commits exempt from touch-set checks.

## SW1 — wiring present

Commands (`git grep -c` prints `<path>:<count>`) and PASS criteria:
- `git grep -ci "status.ps1" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -c "verbatim" -- skills/architect/SKILL.md` → count ≥ 1
  (the print-it-verbatim, never-hand-compose rule)
- `git grep -c "## Status display" -- skills/architect/dispatch.md` → count 1
- `git grep -ci "status.sh" -- skills/architect/dispatch.md` → count ≥ 1

## SW2 — size guard with headroom evidence

```powershell
$files='skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'
$total=($files | ForEach-Object { (Get-Content $_ | Where-Object { $_.Trim() }).Count } | Measure-Object -Sum).Sum
"TOTAL $total"
```
PASS: `TOTAL` ≤ 799 (measured 789 at freeze; net addition ≤ 10). Pure
PowerShell on purpose — the shared uv cache is corrupt in this sandbox.

## SW3 — no collateral edits

- `git diff --name-only <freeze-sha-on-your-HEAD>..HEAD` at report time plus
  final `git status --short` must show only the two owned files (and the
  exempt report). Paste both.
- `git grep -c "## Factory Loop\|### 4. Factory Loop" -- skills/architect/SKILL.md` → count ≥ 1 (section survived)
- Pointer integrity: every `dispatch.md section` pointer named in SKILL.md
  still resolves — list each and its heading grep count of 1.
