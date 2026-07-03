# Spec: loop-tuning — watchdog done-signal, 5-minute autonomy, oddity research, parallel rules

Four small policy/mechanism changes from the status-tree retro and human
directives.

## Approval record

Pre-approved at invocation, 2026-07-03 (verbatim): "yes, do the watchdog
done signal fix. does the oddities rule let the orchestrator agent figure
out a new plan? ... It should be orchestrator who then updates the plan and
issues and checks then respawns a builder to implement the orchestrator's
new plan (track everything in git issues smoothly). Second, when you pause
to ask the human a question, wait 5m then if no answer, use the
orchestrator's best judgement and continue. If the orchestrator determines
it may need some web research done to help figure it out, then the
orchestrator can spin up 1 or more builder agents to do the research and
then figure out the best plan from there after an oddities trigger, update
the issue and checks, and then launch a builder with the new plan. The 5m
wait until it lets the orchestrator just answer the question goes for spec,
or oddities, or anywhere it asks the user a question. Second, analyze the
work you did in this pipeline. Do you see further simple parallelization
optimizations you can implement?"

Orchestrator carve-out, flagged in-session and unvetoed: for irreversible or
destructive actions, 5-minute silence resolves to the NON-destructive path;
`docs/STOP` remains absolute.

## Goal

1. **Watchdog done-signal:** a job is done when its report file ENDS with a
   `STATUS:` line, not when the file exists (twice-observed false ALL_DONE:
   run #36 respawn case, run #43 incremental write).
2. **5-minute autonomy:** every human question anywhere in the loop — spec
   approval, oddity escalations, rail rulings — waits ~5 minutes, then the
   orchestrator rules with recorded reasoning and continues; the ruling is
   posted on the tracking issue for after-the-fact veto. Replaces the
   park-and-poll + 7-day fail-safe machinery. Carve-out: irreversible/
   destructive choices resolve to the non-destructive option on silence;
   `docs/STOP` absolute.
3. **Oddity → research → re-plan, orchestrator-owned:** codify that oddity
   and failure re-planning belongs to the orchestrator, which MAY fan out
   one or more researcher agents (web research) to inform the new plan,
   then updates the spec/issue/checks in git and the tracker, then respawns
   a fresh builder to implement it. Builders never re-plan.
4. **Parallel dispatch rules:** judges dispatch immediately and run
   concurrently for every DONE; the ready-issue frontier recomputes on
   EVERY merge, not at wave boundaries; independent orchestrator
   bookkeeping batches into parallel calls. Merges, synthesis, and the
   stress-test stay serial by design.

## Non-goals

No changes to builder flow, check freezing, judging, tiering, status tree,
or config. No new files beyond docs.

## Interface contract

- Watchdog: done test = last non-blank line of the report file starts with
  `STATUS:` (encoding-aware read). `INTEGRATED`/`STALL`/`REPEAT` semantics
  unchanged. Both scripts identical in behavior; markers unchanged
  (validator contract untouched).
- SKILL.md carries the 5-minute policy as the Spec Approval text (replacing
  the park/7-day block) plus one sentence extending it to all human
  questions, with the destructive carve-out; and the oddity bullet gains
  the research-then-re-plan sentence pointing at `research.md`.
- loop.md carries the parallel rules (three short lines) and the failure
  ladder gains the researcher-fan-out option.
- Combined SKILL.md+loop.md+dispatch.md non-blank total stays ≤ 800
  (measured 794; the replaced park block frees ~5).

## Scope: three issues

| Issue | Files |
|---|---|
| A `tuning-watchdog` | `skills/architect/watchdog.ps1`, `skills/architect/watchdog.sh` |
| B `tuning-policy` | `skills/architect/SKILL.md`, `skills/architect/loop.md` |
| C `tuning-docs` (blocked by A, B) | `README.md`, `DESIGN.md`, `CONTEXT.md` |

## Assumptions (pre-approved unless vetoed)

- **A1.** The 5-minute wait is implemented as: in-session ask (~60s harness
  prompt) then one scheduled ~4-minute recheck, then the recorded ruling —
  total ≈5 minutes.
- **A2.** DESIGN's approval-decision entry is updated (not deleted): the
  GH-30-day/OWASP default-deny evidence stands, with the human's 2026-07-03
  directive recorded as the overriding product decision and the carve-out
  noted.
- **A3.** Oddity-research uses the existing inline fan-out mechanics
  (`research.md`); no new researcher machinery.
- **A4.** Tier: builders `codex/tier-down` (gpt-5.5 high); judges
  `codex/best` (xhigh). Checks under `docs/checks/`, reports under
  `docs/jobs/`, branch `factory/loop-tuning`.

## Validation strategy

A: functional fixture tests — report absent → not done; report mid-write
(no STATUS line) → not done (no ALL_DONE within a short window); report
ending `STATUS: COMPLETE` → ALL_DONE with evidence; STALL/INTEGRATED paths
regression. B: contract greps + size guard with the PS-native count. C:
mention checks + link integrity. Composite: validator green; live watchdog
smoke on a synthetic config; size guard ≤800.

## Preflight evidence

Same-session: gh 2.96.0 auth OK; codex 0.139.0 canary SHELLS_OK; size
guard 794/800 at branch cut.
