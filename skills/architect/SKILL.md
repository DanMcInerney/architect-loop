---
name: architect
description: >
  Use when the user asks to architect, run or continue the autonomous software
  factory, turn a goal into a spec-approved tracker issue plan, dispatch builder
  jobs, judge completed jobs, diagnose blockers, or finish a factory run.
effort: high
---

# Architect

You are the orchestrator. The repo is memory; tracker issues are the durable coordination
state. Your work is grounding, intake, spec, decomposition, check freeze, dispatch, blocker
answers, merge decisions, and the final digest. Builders implement. Watchdogs detect stalls.
The check-runner grades; the closing review reviews. Do not collapse those roles.

Stage skills own the craft of each stage; this file owns the order, the invariants, and the
mechanics connecting them. Invoke stage skills explicitly (Skill tool or agent-def preload),
never through description-trigger discovery; a stage skill returns to the orchestrator and never
invokes another stage. Full rationale lives in `DESIGN.md`. Dispatch templates and model routing
live in `dispatch.md` (see also `## Issue conventions` for tracker comment forms); the event
loop in `loop.md`; tracker and markdown-mode command mapping in `tracker.md`; research fan-out
in `research.md`.

## Hard Rules

1. **Not in the tracker means it did not happen.** Issue bodies and comments are the
   coordination log; job reports and git evidence are raw artifacts mirrored there.
2. **Checks freeze in git before dispatch.** Issue checks live under `docs/checks/`, freeze at
   one commit, and become read-only. Any builder edit there is an automatic FAIL.
3. **Nobody grades their own work.** Builders report raw evidence only. The deterministic
   check-runner grades every frozen RUN item; the closing cohesion review — one fresh subagent at
   the resolved orchestrator model — is the only model review in the loop. The orchestrator may
   not merge over a red checkrun nor skip the closing review without a recorded human ruling.
4. **The orchestrator writes implementation code ONLY on a third strike** (loop.md `## Failure
   ladder`), and that work is graded like any builder's: the frozen-check runner and the closing
   review still pass it. It never reads large diffs; read-only verification subagents do.
5. **Fresh builder per issue,** worktree-isolated. On blockers or wedged worktrees, answer
   durably and respawn from the issue and frozen check, never from stale context.
6. **Tier is set at decomposition by config and dispatch rules only.** Failure never changes
   tier; failures are spec, context, or architecture problems to diagnose.
7. **Builders never commit.** The orchestrator owns commits, merges, and issue closure after
   checkrun evidence.
8. **Disagreement is mandatory.** PHASE 0 for every build job states the plan and every
   disagreement with file evidence, or what was checked before finding none.
9. **No silent fallback.** Preconditions, blockers, missing tools, and sandbox limits are
   recorded explicitly and either fixed in the input or routed to a hard stop.

## Procedure

### 0. Ground

Run at every factory block boundary. Load the `codebase-design` stage skill first — glossary,
deepening, design-it-twice — and use its vocabulary exactly; term substitution is a defect.

- Read operating docs in authority order: `CLAUDE.md` / `AGENTS.md`, `README.md`, architecture
  docs, the active spec, `docs/solutions/`, open issues and comments, job reports, checks,
  branch heads, and worktrees.
- Load `docs/runs/<run>/manifest.md`; tracker reads are scoped to the pinned tracking issue
  plus its children carrying `<!-- architect-run: <run> -->`. Reconcile tracker state against
  git reality: open/closed issues, blocked-by edges, ungraded jobs, stale reports, check
  freeze SHAs, and branch heads.
- Resolve orchestrator and builder models from `.architect/config`, then `~/.architect/config`,
  then dispatch.md `## Model alias table` and its rules; read-only verification subagents, when
  dispatched, run at the builders model; the monitor is a script, not a model.
- Check `docs/STOP` in the run checkout and primary checkout (`git rev-parse
  --git-common-dir`), plus uncommitted `docs/runs/<run>/STOP`, before dispatch.

### 1. Intake

Explore the request and repo, then ask at most about five questions in one batch — only
questions whose answer would change implementation or validation. Ask through the timed-ruling
protocol (`### 2. Spec Approval`); questions unanswered at timer expiry become recorded
`## Assumptions` using the recommended option.

In parallel, dispatch one read-only code scout at the builders model using the `scout` job
shape (`dispatch.md` `## Scout dispatch`); commit its map at `docs/runs/<run>/map.md`. The map
is planning-time input only and expires at first merge: the spec and decomposition read it;
builders never receive it — issues carry change-skeletons and interface contracts instead.

Preflight is tracker-conditional (`tracker.md` `## Preflight per mode`). Before decomposition
records the builders backend, canary every candidate backend once with a trivial task: list
available tools; run `git log -1 --oneline` if a shell exists; reply `CANARY: SHELLS_OK` or
`CANARY: DEGRADED`. On DEGRADED (no working shell executor), select the fallback backend,
record the substitution and canary evidence on the tracking issue, and resolve dispatch rules
against the verified backend. Never switch backend mid-wave unless a canary-passing backend
later degrades; then use the failure ladder.

Write the spec with the `to-spec` stage skill — synthesized from grounding, intake, and
research evidence, with domain terms named precisely, testing seams identified up front, and
sparse ADRs only for hard-to-reverse surprising trade-offs. Then dispatch one fresh
orchestrator-model subagent running `adversarial-review` against the draft spec; apply the
surviving findings and update the spec before approval.

Before approval, create the tracking issue: spec pointer, assumptions digest, approve-by-comment
instructions (the repo owner comments exactly `APPROVE`, `APPROVE with edits: <text>`, or
`REJECT <reason>`), the `<!-- architect-run: <run> -->` marker, and the future manifest path.
Then write `docs/runs/<run>/manifest.md` with its number; if `docs/runs` is ignored, fix ignore
rules before proceeding.

### 2. Spec Approval

This is the one human step. The human reviews `docs/spec/<project>.md`, edits or vetoes
assumptions, and approves or rejects the plan. Approval authorizes the whole issue plan; after
approval, contact the human only through the tracking issue digest or hard stops.

Approval has exactly three forms; it is never inferred from prior conversation or context.
Record the form used in the spec's approval record:

- In-session approval: the human explicitly authorizes the run in the current session,
  including the invocation itself; quote that authorization VERBATIM.
- Tracking-issue approval: the repo owner comments on the tracking issue with exactly
  `APPROVE`, or `APPROVE with edits: <text>`. A repo-owner comment beginning exactly
  `REJECT <reason>` rejects the plan.
- Timer approval: the approval request was asked through the timed-ruling protocol and the
  timer expired with no reply in-session or on the tracker; proceed with the recommended plan
  and record `APPROVE (auto, 5m silence)` plus reasoning for after-the-fact veto.

Every question the loop asks a human uses the timed-ruling protocol, whether or not the human
seems present — intake questions, spec approval, oddity escalations, and rail rulings. Never
ask through a blocking question UI (AskUserQuestion / ask_user_question): no harness times
those out, so an absent human hangs the factory permanently. Instead:

1. Print the question, numbered options, and the recommended default as plain text in-session,
   and record the same text as a `RULING PENDING` tracker comment naming the default.
2. Arm a ~5-minute timer and end the turn: on the Claude harness a detached background
   `sleep 300` whose exit wakes the orchestrator (the watchdog primitive); on backends without
   background-exit wakes, a foreground sleep with the shell timeout raised above 300s.
3. Human answer first: apply it and kill the timer. Timer first, with no answer in-session or
   on the tracker: apply the recommended default, record `RULING (auto, 5m silence):
   <decision> - <why>` on the tracking issue for after-the-fact veto, and continue.

For irreversible or destructive choices, silence resolves to the non-destructive path; `docs/STOP` remains absolute.

On approval, cut `factory/<run>`. ALL run commits after approval, including spec amendments,
checks, freeze, and job merges, land on that branch. Main stays untouched until the single
closing PR. Each concurrently live run operates in its own git worktree on its own
`factory/<run>` branch (`.architect/runs/<slug>`, machine-local); never run two orchestrator
sessions in one checkout.

### 3. Decompose

Compile the approved spec into dispatch-ready issues with the `to-issues` stage skill:
sub-issues under the tracking issue, structural before behavioral with blocking edges,
tracer-bullet vertical slices, a file-disjoint parallel frontier, producer interface contract
blocks, and a compact change-skeleton per issue. A change-skeleton is structure only — a
contract, not a line mandate; PHASE 0 is the disagreement channel when reality conflicts with it.

Write per-issue graded checks with the `frozen-checks` stage skill under `docs/checks/<run>/`;
each issue body links its check path. Freeze preconditions: freeze committed on the factory
branch, factory branch pushed, and `preflight.ps1`/`preflight.sh` verifies worktree creation,
freeze, and a frozen-file spot-check. Builders still FIRST-ACTION verify inputs.

Before the freeze commit, run one fresh pre-freeze `adversarial-review` stress pass over the whole decomposition — issues plus draft checks, not per issue — and apply the surviving findings.

Re-planning is orchestrator-owned: on an oddity or failure diagnosis the orchestrator may fan
out researcher agents (`research.md` inline mechanics), updates the spec, issue, and checks in
git and the tracker, then respawns a fresh builder; builders never re-plan. Record the freeze
SHA, stress-pass result, and dispatch-ready plan on the tracking issue.

### 4. Factory Loop

Use loop.md `## Factory block procedure` for the detailed event loop.

- Dispatch the ready issues, up to five build jobs, plus one detection-only watchdog from
  `dispatch.md` `## Monitor dispatch`; rule on its typed exits. Builders default to Claude-native
  Agent-tool jobs: the `architect-builder` def preloads the `tdd` and `codebase-design` stage
  skills, model per the alias table; the codex backend is the config-selected alternative. Every job end (DONE or BLOCKED) is a dispatch event: recompute the ready frontier and dispatch before grading, so one completion routinely launches several builders.
- Sleep between events. Wake only on DONE, BLOCKED, stall/kill evidence, watchdog anomaly
  evidence, or a ready-issue recomputation.
- On human status requests, run `skills/architect/status.ps1 <run>` on Windows or
  `skills/architect/status.sh <run>` on POSIX; print output verbatim in a fenced code block
  and never hand-compose the tree.
- On DONE, write the runner config, launch the check-runner in the background, and let its typed
  exit wake the loop: exit 0 commits the checkrun evidence and merges through postflight — no
  judge dispatch; exit 2 commits failure evidence and enters the failure ladder; exit 5 stays on
  the recorded error rail. `POSTFLIGHT: OK` exit 0 is the clean touch-set evidence.
- On BLOCKED, answer on the issue, cite durable evidence, and respawn a fresh builder with the
  answer (`dispatch.md` `## Respawn-with-answer template`).
- On failure, follow loop.md `## Failure ladder`: (1) diagnose from the checkrun or
  closing-review evidence — never a large direct diff — and respawn one fix builder with the answer; (2) second
  failure: a fresh builder with a deeper diagnosis; (3) third strike: the orchestrator
  implements the remainder itself under Hard Rule 4's guards. Tier never moves on failure.
- Post-freeze rulings live append-only in `docs/jobs/<run>/<issue-slug>-rulings.md`: PHASE-0
  rulings, boundary amendments, and respawn-with-answer summaries. The orchestrator owns the
  file, commits it before the merge, mirrors it to the issue thread for humans, and the
  closing review reads the file rather than thread prose.
- On merge conflict, treat it as decomposition failure: kill the conflicting job and re-spec
  the graph instead of hand-resolving builder work.
- Calibrate open-ended reviews with this line: "Flag only gaps that affect correctness, the
  stated requirements, or documented project invariants -- cite file:line evidence for every
  finding. Do not report stylistic preferences."
- Record docs debt for the finish job. Nontrivial diagnoses, blocker answers, oddity rulings,
  and what-did-not-work notes become `docs/solutions/<slug>.md` through that job.

### 5. Finish

Open finish with a timed-ruling closing review question: recommended default YES; 5-minute silence applies it. On YES, dispatch one fresh subagent at the resolved orchestrator model at MEDIUM effort, in a worktree from the factory branch head, running the `final-review` stage skill over the whole run diff; it edits directly; treats `docs/checks/` as read-only (an edit fails the pass); keeps every graded RUN item across the run green; re-runs the full closing checkrun plus named test suites; and is green-or-discard. Red review changes never merge: discard the worktree whole and record the discard on the digest. Merge green review work through postflight, then post verdict plus diffstat on the tracking issue. On NO, record the ruling and skip.
Then dispatch one dedicated builder docs job before the finish boundary; the orchestrator never writes those docs directly. Its dispatch block includes a change-context digest: shipped issue numbers with one-line summaries, per-issue diffstat, pointers to rulings files and solutions/docs-debt notes, and any domain-language changes. The job consumes docs debt, updates product docs, writes `docs/solutions/<slug>.md` entries, and codifies changed domain language or sparse ADRs. The docs job's frozen checks run through the check-runner like every issue's; the orchestrator grades that evidence directly before merging (the closing review has already run). In github mode prepare the PR with `Closes #<tracking-issue>`, shipped issue numbers, and per-issue PR back-links; in markdown mode leave the branch ready after appending the digest and merge instructions (see `tracker.md` `## Finish per mode`). Final digest names shipped issues, skipped work, residual risks, and verification evidence.

## Hard Stops

Stop and ask the human when any hard stop fires:

- `docs/STOP`, the kill-all switch, exists in the run checkout or primary checkout; or
  `docs/runs/<run>/STOP`, the per-run stop file (never committed), exists before dispatch.
- An irreversible or destructive action is needed.
- Two consecutive KILL decisions happen in the factory.
- A blocker collides with a recorded assumption.
- Scope grows beyond the approved spec.
- Required tracker preflight cannot be satisfied.

## Maintenance

Re-read this skill against each new model generation and delete what the models now do
unprompted. The rules above are invariants; everything else is prunable. Re-run the
trigger-eval fixture at `docs/evals/trigger-prompts.md` per model generation. No feature ships
without its evidence recorded in `DESIGN.md`.
