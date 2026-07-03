# Checks: tuning-docs

Purpose: verify the docs closure for the loop-tuning run.
Spec (fix contract): `docs/spec/loop-tuning.md` A2.
Files owned: `README.md`, `DESIGN.md`, `CONTEXT.md`.

Executor: PowerShell primary; native git fine. Orchestrator bookkeeping
commits exempt.

## TD1 — README

- `git grep -ciE "5 minutes|five minutes" -- README.md` → count ≥ 1
- `git grep -ci "STATUS" -- README.md` → count ≥ 1 near the watchdog bullet — quote it.
- The after-the-fact-veto phrasing and destructive carve-out present — quote.
- No sentence still claims a 7-day park: `git grep -ciE "7 days|7-day" -- README.md` → no output.

## TD2 — DESIGN

- The approval entry retains the default-deny evidence AND records the
  2026-07-03 human directive as overriding, with the carve-out — quote both
  parts.
- The watchdog entry cites the twice-observed done-signal evidence and the
  STATUS-line fix — quote.
- One parallel-rules sentence citing run #43's digest — quote.
- `git grep -c "loop-tuning" -- DESIGN.md` → count ≥ 1 (spec cited).

## TD3 — CONTEXT

- Spec approval and Watchdog glossary entries updated — quote each changed line.
- Glossary above retired terms stays clean: PowerShell `sed`-equivalent
  slice piped to word-boundary grep for
  `gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag` → no output.

## TD4 — link integrity self-check

`git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md` — `Test-Path`
each target, paste results. Full validator at composite.
