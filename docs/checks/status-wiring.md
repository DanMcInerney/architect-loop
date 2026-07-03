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
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'
uv run --no-project python -c "t=sum(1 for p in ['skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'] for l in open(p,encoding='utf-8') if l.strip()); print(t)"
```
PASS: printed total ≤ 799 (was 789 at freeze; net addition ≤ 10).

## SW3 — no collateral edits

- `git diff --name-only <freeze-sha-on-your-HEAD>..HEAD` at report time plus
  final `git status --short` must show only the two owned files (and the
  exempt report). Paste both.
- `git grep -c "## Factory Loop\|### 4. Factory Loop" -- skills/architect/SKILL.md` → count ≥ 1 (section survived)
- Pointer integrity: every `dispatch.md section` pointer named in SKILL.md
  still resolves — list each and its heading grep count of 1.
