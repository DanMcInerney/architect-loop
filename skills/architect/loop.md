# Local Factory Loop Reference

The loop is one Opus architect session that dispatches fresh GPT-5.5 Codex
builders and sleeps between events. `.scratch/architect-loop` is the memory.
There is no issue tracker, no committed docs, and no branch/commit finish step.

## Block Procedure

1. Ground from project docs, current `.scratch` state, and Git inspection.
2. Select one local issue-slice file and write/update `state/<slice>/`.
3. Freeze gates, run the stress-test template, fix defects, and re-freeze.
4. Dispatch ready lanes, up to four builders, plus one script watchdog if the
   run is unattended.
5. Sleep until one event occurs:
   - A lane report ends with `STATUS: COMPLETE`, `COMPLETE_WITH_CONCERNS`, or
     `BLOCKED`.
   - The watchdog exits with typed evidence.
   - The human interrupts with a status or stop request.
6. For a completed lane, ingest reports/runs, run the deterministic
   check-runner, judge intent, and decide KILL / CONTINUE / INVALID.
7. For BLOCKED, answer in `.scratch/architect-loop/state/<slice>/rulings.md`,
   update the prompt/spec if needed, and respawn a fresh lane. A running builder
   is not expected to read later comments or rulings.
8. For KILL or INVALID, diagnose from evidence and fix inputs before respawn.
   Do not change model tier.
9. When every accepted lane is judged, write lane patches and `final.patch`.
10. Write `verdict.md` and stop. Do not apply, stage, branch, commit, push, or
    publish unless the human gives a separate explicit instruction.

## Watchdog Protocol

The watchdog detects mechanically and never decides. The architect rules on its
typed line:

| Exit | Prefix | Meaning |
|---|---:|---|
| 0 | `WATCHDOG: ALL_DONE` | Every configured report has a terminal STATUS line. |
| 2 | `WATCHDOG: INTEGRATED` | A worktree or event file vanished; inspect before continuing. |
| 3 | `WATCHDOG: STALL` | Output growth and process activity stopped beyond the hint. |
| 4 | `WATCHDOG: REPEAT` | The last parsed commands repeated mechanically. |

## Failure Ladder

First failure on a lane:

- Check-runner exit 2: diagnose from failing RUN evidence.
- Judge FAIL: diagnose from judge evidence.
- Judge INVALID: fix evidence, template, frozen gates, or the runner contract.
- BLOCKED: answer durably in `rulings.md` and respawn fresh.

Second failure after an architect intervention: re-slice the work or stop and
ask the human. A merge conflict or patch conflict means the lane plan was not
disjoint; re-spec instead of hand-resolving builder work.

## Context Discipline

- Keep the architect context focused on specs, rulings, gate summaries, and
  diffs. Do not paste large builder streams into the conversation.
- Builder JSONL, stderr, final messages, check evidence, and judge reports live
  under `.scratch` and are read on demand.
- Status answers should be grounded in current files or command output, not
  memory.
