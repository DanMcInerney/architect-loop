# Checks: hardening-skill-core

Purpose: verify the durable spec-approval policy and the watchdog pointer
updates in the skill's top file.
Spec (fix contract): `docs/spec/ops-hardening.md` — approval strings in the
Interface contract.
File owned: `skills/architect/SKILL.md`.

Executor: PowerShell primary; native `git.exe` subcommands fine. Orchestrator
bookkeeping commits exempt from touch-set checks.

## SC1 — approval forms and strings

Commands (`git grep -c` prints `<path>:<count>`) and PASS criteria
(all against `skills/architect/SKILL.md`):
- `git grep -c "APPROVE with edits:" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -cE "^\s*.*REJECT" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -c "AWAITING APPROVAL" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -ci "verbatim" -- skills/architect/SKILL.md` → count ≥ 1 (pre-approval recorded verbatim)
- A sentence bans inferred approval — quote it.
- The 7-day bound and fail-safe stop are stated — quote the sentence.

## SC2 — tracking issue moves to intake

Commands and PASS criteria:
- The Intake step's "Done when" (or body) states the tracking issue exists
  with spec pointer + assumptions + approve-by-comment instructions — quote it.
- The Decompose step no longer instructs creating the tracking issue:
  `git grep -in "tracking issue" -- skills/architect/SKILL.md` output quoted;
  the Decompose section's hits must reference the EXISTING tracking issue
  (e.g. "under the tracking issue"), not create a new one.

## SC3 — watchdog pointers

Commands and PASS criteria:
- `git grep -ci "watchdog" -- skills/architect/SKILL.md` → count ≥ 1
- `git grep -c "## Monitor dispatch" -- skills/architect/dispatch.md` → count 1
  (the pointer target still exists; read-only check on an unowned file)
- Every `dispatch.md section` / `loop.md section` pointer named in SKILL.md
  resolves to a real heading — list each pointer and its grep count 1.

## SC4 — no regressions

Commands and PASS criteria:
- `git grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" -- skills/architect/SKILL.md` → no output (renamed vocabulary intact)
- Frontmatter intact: first 5 lines contain `name: architect` — quote.
- Size guard: same command as DB7 → total ≤ 800.
