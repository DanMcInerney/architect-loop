# Factory-loop reference

The loop is one orchestrator session that runs the factory to completion after
the spec approval approves the issue plan. GitHub issues carry coordination
state; git carries specs and frozen checks. The orchestrator dispatches the
ready issues, sleeps, and wakes only on an event.

## Factory block procedure

1. **Dispatch the ready issues.** Compute the ready issues of the approved
   plan: up to 5 builder jobs plus one monitor subagent (see Monitor protocol,
   and `dispatch.md` "## Monitor dispatch"). Check `docs/STOP` before every
   wave.
2. **Sleep.** Zero orchestrator work between dispatch and the next event —
   no polling.
3. **Wake on one event**, exactly one of:
   - **Job DONE.** Send the fixed judge template from `dispatch.md` to one
     fresh judge subagent; record the verdict in an issue comment (see
     Verdict comments); merge on PASS, diagnose on FAIL (see Failure
     ladder).
   - **Job BLOCKED.** A blocker comment on the issue is a completion event.
     Read it, rule an answer, and respawn a fresh builder job on the same
     issue with the answer in its spawn context (see `dispatch.md`
     "## Respawn-with-answer template"). A running job never re-reads its
     own comments — the spawn context is the only delivery channel.
   - **Monitor ANOMALY.** Read the evidence report and rule one of:
     healthy-long-run (redispatch the monitor, sleep again), needs a nudge
     or answer, or wedged (kill the job, discard its worktree, respawn
     from the frozen check with a route-around).
4. **Recompute the ready issues.** Closing an issue may unblock others;
   recompute and dispatch the next wave.
5. **Repeat** until no issues remain open, then post the escalation
   digest's end-of-run summary on the tracking issue.

## Monitor protocol

One detection-only subagent (cheapest tier, e.g. haiku:low) is dispatched
as a background subagent whose completion re-invokes the orchestrator; the
exit is the alert channel. Teammate-style spawns idle instead of exiting
and require a formal `shutdown_request` to stand down, so use that
mechanism only when a teammate spawn is unavoidable. The monitor is sent
with each wave — see `dispatch.md` "## Monitor dispatch". It sweeps every
10 min: for each in-flight job it checks report/output file growth since
the last sweep, process-tree existence/activity, and a repeated-identical-
command tail check. All healthy -> keep looping. All jobs done -> exit
quietly. In a normal all-green wave, harness notifications cover every
event and the monitor's quiet exit is its only output; that is success,
not waste. Anomaly -> exit immediately with an evidence report: job id,
minutes since last growth, tail excerpt, process state.

The monitor never kills, never nudges, never decides — only the orchestrator
rules on its evidence. Duration hints carried in issue bodies (e.g. "full
suite ~20m") suppress false flags on legitimately long tests; liveness is
output growth and process activity, never wall-clock alone, and there are
no per-command kill ceilings anywhere in this loop.

## Verdict comments

Judgment is recorded on the issue, not in a file. At judgment, one comment
is posted on the job's issue with: per-check PASS/FAIL/INVALID, a
checks-integrity verdict, a diff-vs-intent verdict, the slice call
KILL/CONTINUE, and the decisive reason tied to raw evidence — exact `gh`
commands and comment format live in `dispatch.md` "## Issue conventions".
The judge's intent context is exactly the frozen check file, spec, job
report, and `docs/jobs/<issue-slug>-rulings.md`. That rulings file is
orchestrator-owned, append-only, and committed before judge dispatch; if it
is absent, there are no post-freeze rulings. Judge dispatch blocks carry no
ruling prose.
The issue is closed on merge. No verdict comment on an issue means the
next factory block must not build on it as accepted; the orchestrator may re-run
judgment with a fresh judge if evidence is missing, but may not fill in a
verdict from memory.

## Failure ladder

First FAIL on an issue: the orchestrator diagnoses from the judge's evidence (not
the full diff), fixes the input — issue text, missing context, or a
forbidden-pattern note — and respawns a fresh builder job at the same tier.
The tier is set once, at decomposition (config plus dispatch rules), and
never changes because a job failed; a failure is a spec or context problem
the orchestrator fixes, never a signal to move the tier. Second FAIL on the same
issue after an orchestrator intervention: re-decompose the issue or escalate it to
the digest. A merge conflict is a decomposition failure, not a build
failure: kill the conflicting job and re-spec; never hand-resolve builder
conflicts.

## Escalation digest

Batched on the tracking issue instead of interleaved per-job noise:

- completed and failed jobs, with verdicts
- open blockers and the answers given
- decisions the approved spec genuinely does not answer

Ask-the-human items are batched here unless a hard stop below requires an
immediate stop.

## Hard Stops

| Situation | Hard stop |
|---|---|
| `docs/STOP` exists | Stop before dispatching the next wave. |
| No verdict comment for completed work | Do not build on it as accepted. |
| Builder touched `docs/checks/` | Automatic FAIL for that job. |
| Merge conflict | Decomposition failure: kill the job, re-spec. |
| Second FAIL on the same issue | Re-decompose or escalate to the digest. |
| Two consecutive KILLs | Stop the factory and ask the human. |
| Monitor reports an anomaly | Orchestrator rules before any further dispatch on that job. |
| Blocker collides with a recorded assumption | Ask the human; it is a spec approval decision surfacing late. |
| Session context degrades | End the session; the next session grounds from the issue tracker and git. |
| Scope grows beyond the approved spec | Stop the factory. |
| High-stakes issue | Add cross-model review before CONTINUE. |

## Context discipline

- Delegate heavy reading to judge, monitor, or builder subagents; the orchestrator
  stays thin and never reads a full diff directly.
- The issue tracker and git are the memory: specs, frozen checks, verdict
  comments, and job reports carry state across sessions, not the
  conversation.
- Compact proactively when the harness supports it.
- Ending a degraded session is free because the tracker and git are the
  memory.
