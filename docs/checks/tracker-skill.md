# Checks: tracker-skill

Purpose: verify the tracker-conditional pointer swaps under the net-zero
constraint.
Spec (fix contract): `docs/spec/tracker-markdown.md` A5.
Files owned: `skills/architect/SKILL.md`, `skills/architect/loop.md`,
`skills/architect/dispatch.md`.

Executor: PowerShell primary. Orchestrator bookkeeping commits exempt.

## TK1 — pointers present

- `git grep -c "tracker.md" -- skills/architect/SKILL.md` → count ≥ 2
  (pointer list + preflight paragraph)
- `git grep -c "## Preflight per mode" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -c "tracker.md" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -cE "^tracker = markdown" -- skills/architect/dispatch.md` → count 1 (config example line)

## TK2 — hard stop reworded, no unconditional gh preflight

- `git grep -c "Required tracker preflight" -- skills/architect/SKILL.md` → count 1
- `git grep -c "Required GitHub or" -- skills/architect/SKILL.md` → no output
- The intake preflight paragraph names both modes — quote it.
- `git grep -ci "push-if-remote-exists" -- skills/architect/SKILL.md` → count ≥ 1

## TK3 — net-zero size (the wall)

```powershell
$files='skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'
$total=($files | ForEach-Object { (Get-Content $_ | Where-Object { $_.Trim() }).Count } | Measure-Object -Sum).Sum
"TOTAL $total"
```
PASS: TOTAL ≤ 800 (was exactly 800 at freeze).

## TK4 — nothing lost

- Pointer integrity: every `dispatch.md section` / `loop.md section` pointer
  named in SKILL.md resolves — list each with heading grep count 1. For
  `tracker.md` pointers, verify the pointer TEXT names exactly the
  spec-pinned headings (`## Preflight per mode`, `## Finish per mode`,
  `## Command mapping`) — resolution against the sibling-built file is a
  composite check, not yours.
- The nine Hard Rules headings/numbers survive; Finish still requires the
  digest and per-issue back-links in github mode — quote the Finish
  sentences.
- Retired-term sweep: `git grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" -- skills/architect/SKILL.md skills/architect/loop.md skills/architect/dispatch.md` → no output.
- Final `git status --short` shows only owned files + exempt report — paste.
