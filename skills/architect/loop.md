# Factory-loop reference

## Contents

- Factory block procedure
- Monitor protocol
- Verdict comments
- Failure ladder
- Escalation digest
- Hard Stops
- Context discipline

The loop is one orchestrator session that runs the factory to completion after
the spec approval approves the issue plan. Tracker issues carry coordination
state; git carries specs and frozen checks. The orchestrator dispatches the
ready issues, sleeps, and wakes only on an event.
Parallel rules: harness-native result-bearing subagents (Claude Agent tool) dispatch synchronously with `run_in_background: false` so the result returns as the tool result; codex-backend subagents keep the background `codex exec -o <file>` typed-exit path, whose process exit wakes the loop; a job END (DONE or BLOCKED) is a dispatch event that recomputes the full ready frontier and dispatches every ready issue into a free slot before grading (Factory block procedure step 3); merges recompute the frontier too, since a merge can unblock issues no END could; independent orchestrator bookkeeping batches into parallel calls; merges, synthesis, and the pre-freeze `adversarial-review` stress pass stay serial by design.

## Factory block procedure

1. **Dispatch the ready issues.** Compute the ready issues of the approved
   plan: up to 5 builder jobs plus one monitor subagent (see Monitor protocol,
   and `dispatch.md` "## Monitor dispatch"). Check `docs/STOP` and
   `docs/runs/<run>/STOP` before every wave.
2. **Sleep.** Zero orchestrator work between dispatch and the next event —
   no polling.
3. **Wake on one event**, exactly one of:
   - **Job DONE.** A job END (DONE or BLOCKED) is a dispatch event: before grading the finished job, recompute the full ready frontier — run `skills/architect/ground.ps1|.sh <run>` and read its `FRONTIER:` line as the source, covering newly unblocked issues AND previously-ready issues queued beyond the concurrency cap — and dispatch every ready issue into a free slot; one completion may launch multiple builders. Merges still recompute the frontier too, since a merge can unblock issues no END could. Ordering: after that recompute-and-dispatch, write the runner config; launch `check-runner.ps1` or `check-runner.sh` as a background process whose typed exit is the next wake. Exit 0: commit the checkrun artifact `docs/jobs/<run>/<issue-slug>-checkrun.md`, post the checkrun result on the issue, then run `postflight.ps1` or `postflight.sh` — no per-issue model review exists on this path: exit 0 `POSTFLIGHT: OK` means merge completed with clean touch-set evidence; exit 2 `POSTFLIGHT: VIOLATION` is automatic FAIL evidence; exit 3 `POSTFLIGHT: CONFLICT` is the decomposition-failure rail; exit 5 `POSTFLIGHT: ERROR` falls back to the recorded manual integration sequence in `dispatch.md`. Exit 2: commit failure evidence and enter the Failure ladder. Exit 5: stay on the recorded error rail. The finish-boundary docs job takes the same path (see SKILL.md `### 5. Finish`): the orchestrator grades its checkrun evidence directly before merge.
   - **Job BLOCKED.** A blocker comment on the issue is a completion event.
     Read it, rule an answer, and respawn a fresh builder job on the same
     issue with the answer in its spawn context (see `dispatch.md`
     "## Respawn-with-answer template"). A running job never re-reads its
     own comments — the spawn context is the only delivery channel.
   - **Monitor ANOMALY.** Read the evidence report and rule one of:
     healthy-long-run (redispatch the monitor, sleep again), needs a nudge
     or answer, or wedged (kill the job, discard its worktree, respawn
     from the frozen check with a route-around).
   - **Ruling timer expiry.** A pending timed ruling's timer exit is a wake:
     if the ruling is still unanswered in-session and on the tracker, apply
     the recommended default and record the auto-ruling (timed-ruling
     protocol, SKILL.md "### 2. Spec Approval"); already resolved is a no-op.
4. **Recompute the ready issues.** Closing an issue may unblock others; rerun
   `ground.ps1|.sh <run>`, read its `FRONTIER:` line, and dispatch the next
   wave from it.
5. **Finish boundary.** When build issues close, run the SKILL.md `### 5. Finish` timed-ruling closing review before the docs job: default YES, 5-minute silence applies; YES uses one fresh resolved-orchestrator-model MEDIUM subagent from the factory branch head running the `final-review` stage skill — review basis spec -> run diff -> published interface contract blocks (the scout map expired at first merge) — editing directly with `docs/checks/` read-only, keeping every graded RUN green, rerunning the full closing checkrun plus named suites, and merging only green review work through postflight. Red review changes are discarded whole and recorded on the digest; verdict plus diffstat is posted on the tracking issue.
6. **Repeat** until no issues remain open, the closing review/docs finish boundary is handled, then post the escalation digest's end-of-run summary on the tracking issue.

## Monitor protocol

Launch the script watchdog at wave dispatch from `dispatch.md` "## Monitor
dispatch". The watchdog runs as a background process and its typed exit wakes
the orchestrator. It detects mechanically and never kills, nudges, or judges;
the orchestrator rules on the evidence.

Ruling options:

- Exit 0 `WATCHDOG: ALL_DONE` -> proceed to the grading backlog (check-runner
  per report) for every report listed by path and byte size.
- Exit 2 `WATCHDOG: INTEGRATED` -> benign mid-sweep integration; relaunch the
  watchdog if any jobs remain in flight.
- Exit 3 `WATCHDOG: STALL` -> run the rescue ladder: inspect the named job,
  kill stuck children if needed, discard wedged worktrees, and respawn from
  the frozen check with a route-around.
- Exit 4 `WATCHDOG: REPEAT` -> rule intentional-vs-stuck before action; the
  OpenHands false-positive caveat applies to deliberate polling loops.

Backends without background-exit notifications use the LLM fallback template
in `dispatch.md` "## Monitor dispatch". The fallback keeps the same
detection-only boundary and per-job evidence requirements.

## Verdict comments

Grading is recorded on the issue, not in a file. At each job close, one comment is posted on the job's issue with: the check-runner typed summary (`CHECKRUN SUMMARY` line plus typed exit), the postflight result, the slice call KILL/CONTINUE, and the decisive reason tied to raw evidence; exact tracker comment format lives in `dispatch.md` "## Issue conventions". The closing cohesion review posts the run-level verdict — findings with file:line evidence, diffstat, and the green-or-discard call — on the tracking issue.
The checkrun artifact `docs/jobs/<run>/<issue-slug>-checkrun.md` is committed before the merge. The rulings file `docs/jobs/<run>/<issue-slug>-rulings.md` is orchestrator-owned, append-only, and committed before the merge; if it is absent, there are no post-freeze rulings; the closing review reads rulings files rather than thread prose.
The issue is closed on merge. No checkrun-result comment on an issue means the
next factory block must not build on it as accepted; the orchestrator may re-run
the check-runner if evidence is missing, but may not fill in a result from memory.

For ANY backgrounded subagent that goes idle without its expected deliverable,
use the recovery ladder in order: retrieve its output via the harness task-output
mechanism; nudge once asking it to deliver the artifact; discard it and respawn
fresh. The orchestrator never authors a missing result. The sync-dispatch rule
(`run_in_background: false`) applies to any result-bearing Claude Agent-tool
subagent — closing review, scout, adversarial review, optional verification —
but harnesses have been observed to run such spawns async regardless: an idle
notification without the deliverable gets exactly one poke requesting delivery
in the deliverable's fixed format before escalation.

Close-out: after processing a subagent's final result — verdict, report, or
fix — release or stop its session in the same turn, batching independent
close-outs into parallel calls; a lingering idle session is bookkeeping debt
and can shadow names, so never leave one open once its result is consumed. No
polling and no per-close commentary. Before postflight, kill lingering codex
children of any consumed exec; kill any lingering job processes when a job is
discarded.

## Failure ladder

Three rungs on the same issue, ending at a third strike; the tier is set once
at decomposition (config plus dispatch rules) and never changes because a job
failed — a failure is a spec, context, or architecture problem the
orchestrator diagnoses, never a signal to move the tier.

1. First failure: on check-runner exit 2, diagnose from the checkrun evidence
   file's failing items; on a closing-review finding, diagnose from the
   finding's file:line evidence (never the full diff). The
   orchestrator may fan out researcher agents to inform the diagnosis, fixes
   the input — issue text, missing context, or a forbidden-pattern note — and
   respawns one fresh fix builder at the same tier with the answer in its
   spawn context.
2. Second failure: a fresh builder with a deeper orchestrator diagnosis —
   re-read the spec and change-skeleton, question the decomposition assumption
   that failed, and rewrite the issue input before respawning.
3. Third strike: the orchestrator implements the remainder itself — Hard Rule
   4's only license. Its work is graded like any builder's: the frozen-check
   runner and the closing review still pass it; no self-grading in artifacts.

A merge conflict, including postflight exit 3, is a decomposition failure, not
a build failure: kill the conflicting job and re-spec; never hand-resolve
builder conflicts.

## Escalation digest

Batched on the tracking issue instead of interleaved per-job noise:

- completed and failed jobs, with checkrun results
- open blockers and the answers given
- decisions the approved spec genuinely does not answer
- foreign sub-issues under the run parent with wrong author or missing run marker

Ask-the-human items are batched here unless a hard stop below requires an
immediate stop.

## Hard Stops

| Situation | Hard stop |
|---|---|
| `docs/STOP` exists in the run checkout or primary checkout, or `docs/runs/<run>/STOP` exists | Stop before dispatching the next wave; global stop halts all runs, per-run stop halts only this run and is never committed. |
| No checkrun-result comment for completed work | Do not build on it as accepted. |
| Builder touched `docs/checks/` | Automatic FAIL for that job. |
| Foreign sub-issue under the run parent | Never dispatch it; escalate on the tracking-issue digest. |
| Merge conflict or postflight exit 3 | Decomposition failure: kill the job, re-spec. |
| Third strike on the same issue | The orchestrator implements the remainder itself (Hard Rule 4); the frozen-check runner and closing review still grade that work. |
| Two consecutive KILLs | Stop the factory and ask the human. |
| Monitor reports an anomaly | Orchestrator rules before any further dispatch on that job. |
| Blocker collides with a recorded assumption | Ask the human; it is a spec approval decision surfacing late. |
| Session context degrades | End the session; the next session grounds from the issue tracker and git. |
| Scope grows beyond the approved spec | Stop the factory. |
| High-stakes issue | Add cross-model review before CONTINUE. |

## Context discipline

- Delegate heavy reading to review, monitor, or builder subagents; the orchestrator
  stays thin and never reads a full diff directly.
- The issue tracker and git are the memory: specs, frozen checks, checkrun-result
  comments, and job reports carry state across sessions, not the
  conversation.
- Compact proactively when the harness supports it.
