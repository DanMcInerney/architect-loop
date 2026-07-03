# Factory-loop reference

The loop is one brain session that runs the factory to completion after the
spec gate approves the issue DAG. GitHub issues carry coordination state;
git carries specs and frozen gates. The brain dispatches the unblocked
frontier, sleeps, and wakes only on an event.

## Factory block procedure

1. **Dispatch the frontier.** Compute the unblocked frontier of the approved
   DAG: up to 5 brawn lanes plus one monitor subagent (see Monitor protocol,
   and `dispatch.md` "## Monitor dispatch"). Check `docs/STOP` before every
   wave.
2. **Sleep.** Zero orchestrator work between dispatch and the next event —
   no polling.
3. **Wake on one event**, exactly one of:
   - **Lane DONE.** Send the fixed judge template from `dispatch.md` to one
     cold judge subagent; record the verdict in an issue comment (see
     Verdict comments); merge on PASS, diagnose on FAIL (see Failure
     ladder).
   - **Lane BLOCKED.** A blocker comment on the issue is a completion event.
     Read it, rule an answer, and respawn a fresh brawn lane on the same
     issue with the answer in its spawn context (see `dispatch.md`
     "## Respawn-with-answer template"). A running lane never re-reads its
     own comments — the spawn context is the only delivery channel.
   - **Monitor ANOMALY.** Read the evidence report and rule one of:
     healthy-long-run (redispatch the monitor, sleep again), needs a nudge
     or answer, or wedged (kill the lane, discard its worktree, respawn
     from the frozen gate with a route-around).
4. **Recompute the frontier.** Closing an issue may unblock others;
   recompute and dispatch the next wave.
5. **Repeat** until no issues remain open, then post the escalation
   digest's end-of-run summary on the epic issue.

## Monitor protocol

One detection-only subagent (cheapest tier, e.g. haiku:low) is dispatched
with each wave — see `dispatch.md` "## Monitor dispatch". It sweeps every
10 min: for each in-flight lane it checks report/output file growth since
the last sweep, process-tree existence/activity, and a repeated-identical-
command tail check. All healthy -> keep looping. All lanes done -> exit
quietly. Anomaly -> exit immediately with an evidence report: lane id,
minutes since last growth, tail excerpt, process state.

The monitor never kills, never nudges, never decides — only the brain
rules on its evidence. Duration hints carried in issue bodies (e.g. "full
suite ~20m") suppress false flags on legitimately long tests; liveness is
output growth and process activity, never wall-clock alone, and there are
no per-command kill ceilings anywhere in this loop.

## Verdict comments

Judgment is recorded on the issue, not in a file. At judgment, one comment
is posted on the lane's issue with: per-gate PASS/FAIL/INVALID, a
gates-integrity verdict, a diff-vs-intent verdict, the slice call
KILL/CONTINUE, and the decisive reason tied to raw evidence — exact `gh`
commands and comment format live in `dispatch.md` "## Issue conventions".
The issue is closed on merge. No verdict comment on an issue means the
next factory block must not build on it as accepted; the brain may re-run
judgment with a fresh judge if evidence is missing, but may not fill in a
verdict from memory.

## Failure ladder

First FAIL on an issue: the brain diagnoses from the judge's evidence (not
the full diff), fixes the input — issue text, missing context, or a
forbidden-pattern note — and respawns a fresh brawn lane at the same tier.
The tier is set once, at decomposition (config plus dispatch rules), and
never changes because a lane failed; a failure is a spec or context problem
the brain fixes, never a signal to move the tier. Second FAIL on the same
issue after a brain intervention: re-decompose the issue or escalate it to
the digest. A merge conflict is a decomposition failure, not a build
failure: kill the conflicting lane and re-spec; never hand-resolve builder
conflicts.

## Escalation digest

Batched on the epic issue instead of interleaved per-lane noise:

- completed and failed lanes, with verdicts
- open blockers and the answers given
- decisions the approved spec genuinely does not answer

Ask-the-human items are batched here unless a safety rail below requires an
immediate stop.

## Safety rails

| Situation | Rail |
|---|---|
| `docs/STOP` exists | Stop before dispatching the next wave. |
| No verdict comment for completed work | Do not build on it as accepted. |
| Builder touched `docs/gates/` | Automatic FAIL for that lane. |
| Merge conflict | Decomposition failure: kill the lane, re-spec. |
| Second FAIL on the same issue | Re-decompose or escalate to the digest. |
| Two consecutive KILLs | Stop the factory and ask the human. |
| Monitor reports an anomaly | Brain rules before any further dispatch on that lane. |
| Blocker collides with a recorded assumption | Ask the human; it is a spec-gate decision surfacing late. |
| Session context degrades | End the session; the next session grounds from the issue tracker and git. |
| Scope grows beyond the approved spec | Stop the factory. |
| High-stakes issue | Add cross-model review before CONTINUE. |

## Context discipline

- Delegate heavy reading to judge, monitor, or brawn subagents; the brain
  stays thin and never reads a full diff directly.
- The issue tracker and git are the memory: specs, frozen gates, verdict
  comments, and lane reports carry state across sessions, not the
  conversation.
- Compact proactively when the harness supports it.
- Ending a degraded session is free because the tracker and git are the
  memory.
