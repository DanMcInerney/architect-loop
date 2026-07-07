# Factory-loop reference

## Contents

- Factory block procedure
- Monitor protocol
- Verdict comments
- Failure ladder
- Escalation digest
- Hard Stops

One orchestrator session runs the factory to completion once the hardened
plan is published and frozen. Tracker issues carry coordination state; git
carries specs and frozen checks. Parallel rules: CLI-launched builders
(`codex exec -o <file>` or equivalent) cap at 10 concurrent jobs;
harness-native result-bearing subagents use the harness cap (currently 5),
and Claude Agent-tool verification dispatches synchronously with
`run_in_background: false`. A job END (DONE or BLOCKED) is a dispatch event
that recomputes the full ready frontier and dispatches every ready issue
into a free slot before grading; merges recompute the frontier too.
Independent bookkeeping batches into parallel calls; merges and synthesis
stay serial.

## Factory block procedure

1. **Dispatch.** Compute the ready issues from `ground.ps1|.sh <run>`'s
   `FRONTIER:` line, up to the cap. Check `docs/STOP` and
   `docs/runs/<run>/STOP` before every wave. Re-arm one watchdog over all
   in-flight CLI-launched jobs at every dispatch event.
2. **Sleep.** No orchestrator work between events; no polling.
3. **Wake on exactly one event:**
   - **Job DONE.** Recompute the frontier and dispatch into free slots
     first — one completion may launch several builders. Then write the
     runner config and launch `check-runner.ps1|.sh` as a foreground child
     of a long-lived Bash task whose exit is the next wake. Runner exit 0:
     post the checkrun result on the issue (the evidence file
     `docs/jobs/<run>/<issue-slug>-checkrun.md` is local; the comment is the
     durable record), then run `postflight.ps1|.sh` — exit 0
     `POSTFLIGHT: OK` merged with clean touch-set evidence; 2 `VIOLATION`
     automatic FAIL; 3 `CONFLICT` decomposition-failure rail; 5 `ERROR`
     manual-integration fallback (`dispatch.md`). Runner exit 2: post
     failure evidence, enter the Failure ladder. Exit 5: recorded error
     rail.
   - **Job BLOCKED.** The blocker comment is a completion event: rule an
     answer, respawn fresh with the answer in spawn context (`dispatch.md`
     "## Respawn-with-answer template"); a running job never re-reads its
     own comments.
   - **Monitor ANOMALY.** Rule one of: healthy-long-run (re-arm, sleep),
     needs a nudge or answer, or wedged (kill the job, discard its
     worktree, respawn from the frozen check with a route-around).
   - **Ruling timer expiry.** If still unanswered in-session and on the
     tracker, apply the recommended default and record the auto-ruling
     (SKILL.md "## Timed-ruling protocol").
4. **Recompute the frontier** after any close; dispatch the next wave.
5. **Finish boundary.** When build issues close, run SKILL.md
   `### 5. Finish`: the closing test pass, then the unconditional
   final-review dispatch with the test-pass output; GREEN short-circuits to
   integrate, FINDINGS freezes and dispatches the fix wave. Run
   `sweep-deferred.ps1|.sh <run>` before final close.
6. **Repeat** until no issues remain and the finish boundary is handled;
   post the end-of-run summary on the tracking issue.

## Monitor protocol

Launch the script watchdog at every dispatch event (`dispatch.md`
"## Monitor dispatch") over every in-flight CLI-launched job, as a
foreground child of a long-lived Bash task; its exit wakes the orchestrator.
It detects mechanically and never kills, nudges, or judges. CLI jobs must be
wrapped by `run-job.ps1|.sh`; unwrapped jobs cannot be accepted as
`DONE_OK`. Rulings on its typed exits:

- 0 `ALL_DONE` -> grade every report listed by path and byte size.
- 2 `INTEGRATED` -> benign mid-sweep integration; relaunch if jobs remain.
- 3 `STALL` -> inspect; healthy-long-run vs route-around respawn.
- 4 `REPEAT` -> rule intentional-vs-stuck (deliberate polling loops are a
  known false positive).
- 5 `ERROR` -> fix the watchdog config; no partial verdict.
- 6 `REPORT_READY` -> grade only with the missing-exit-truth caveat
  recorded on the issue.
- 7 `ORPHANED` -> let it finish only with a recorded ruling.
- 8 `DEAD` -> discard and respawn with evidence.
- 9 `DONE_FAILED` -> grade as failed or respawn; never accept as done.
- 10 `LEGACY_UNWRAPPED` -> respawn under the wrapper unless a ruling
  accepts legacy evidence for diagnosis only.
- 11 `BLOCKED_ON_TOOL` -> kill or route around the named command; respawn
  with that command form recorded as forbidden or bounded.

Backends that cannot wake on a background process exit use the LLM fallback
template (`dispatch.md` "## Monitor dispatch"), same detection-only rules.

Any backgrounded subagent idle without its deliverable: retrieve output via
the harness task-output mechanism; nudge once; then discard and respawn
fresh. The orchestrator never authors a missing result. Sync dispatch
(`run_in_background: false`) applies to any result-bearing Claude
Agent-tool subagent; harnesses may run such spawns async regardless — one
poke requesting the deliverable in its fixed format, then escalate.

Close-out: after consuming a subagent's final result, release or stop its
session in the same turn, batching independent close-outs into parallel
calls. Before postflight or discard, run `kill-job.ps1|.sh <job-dir>` for
any consumed wrapped job with lingering children.

## Verdict comments

Grading is recorded on the issue, not in a file: one comment per job close
with the `CHECKRUN SUMMARY` line plus typed exit, the postflight result,
the KILL/CONTINUE call, and the decisive reason (format: `dispatch.md`
"## Issue conventions"). The final review's verdict goes on the tracking
issue. The checkrun artifact and the rulings file are local run artifacts
(gitignored); `GRADED-BY-RULING:` in a rulings file makes ground count that
report graded; the closing review receives every rulings file verbatim in
its dispatch block. Issues close on merge. No checkrun comment means not
accepted: the orchestrator may re-run the check-runner, never fill in a
result from memory.

## Failure ladder

Three rungs on the same issue; the tier is set at decomposition and never
changes because a job failed.

1. Diagnose from the checkrun evidence file or the finding's file:line —
   never the full diff. Fix the input (issue text, missing context,
   forbidden-pattern note) and respawn one fresh fix builder with the
   answer in its spawn context; researchers may inform the diagnosis.
2. Fresh builder with a deeper diagnosis: re-read the spec and
   change-skeleton, question the decomposition assumption that failed,
   rewrite the issue input.
3. Third strike: the orchestrator implements the remainder itself (Hard
   Rule 4), still graded by the frozen-check runner. A third strike inside
   the fix wave is a hard stop — the closing review is already spent.

A merge conflict, including postflight exit 3, is a decomposition failure:
kill the conflicting job and re-spec; never hand-resolve builder conflicts.

## Escalation digest

Batched on the tracking issue: completed and failed jobs with checkrun
results; open blockers and answers given; decisions the hardened spec does
not answer; foreign sub-issues under the run parent. Ask-the-human items
batch here unless a hard stop requires an immediate stop.

## Hard Stops

| Situation | Hard stop |
|---|---|
| `docs/STOP` (global) or `docs/runs/<run>/STOP` (this run) exists | Stop before the next wave; the per-run stop is never committed. |
| No checkrun-result comment for completed work | Do not build on it as accepted. |
| Builder touched `docs/checks/` | Automatic FAIL for that job. |
| Foreign sub-issue under the run parent | Never dispatch it; escalate on the digest. |
| Merge conflict or postflight exit 3 | Decomposition failure: kill the job, re-spec. |
| Third strike | Orchestrator implements (Hard Rule 4); the runner still grades. |
| Third strike inside the fix wave | Hard stop — the closing review is spent. |
| Two consecutive KILLs | Stop the factory and ask the human. |
| Monitor anomaly | Orchestrator rules before further dispatch on that job. |
| Blocker collides with a recorded assumption | Ask the human; a spec-level decision surfacing late. |
| Session context degrades | End the session; the next one grounds from tracker and git. |
| Scope grows beyond the hardened spec | Stop the factory. |
| High-stakes issue | Add cross-model review before CONTINUE. |

Context discipline: the orchestrator stays thin — delegate heavy reading,
never read a full diff directly; tracker and git carry state across
sessions; compact proactively when the harness supports it.
