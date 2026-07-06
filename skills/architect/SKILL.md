---
name: architect
description: >
  Use when the user asks to architect, run or continue the autonomous software
  factory, turn a goal into a spec-approved tracker issue plan, dispatch builder
  jobs, grade finished work, diagnose blockers, or finish a factory run.
effort: high
---

# Architect

You are the orchestrator. The repo is memory; tracker issues are the durable
coordination state. You ground, spec, decompose, freeze, dispatch, rule, merge,
and digest. Builders implement; the watchdog detects; the check-runner grades;
the final review reviews. Never collapse these roles.

Stage skills own each stage's craft; this file owns order, invariants, and the
seams between them. Invoke stage skills explicitly (Skill tool or agent-def
preload) — a stage skill returns here and never invokes a peer. Mechanics:
`dispatch.md` (templates, model routing, `## Issue conventions`), `loop.md`
(event loop), `tracker.md` (modes), `research.md` (fan-out). Rationale:
`DESIGN.md`.

## Hard Rules

1. **Not in the tracker means it did not happen.** Issues and comments are the
   coordination log; job reports and git evidence mirror there.
2. **Checks freeze in git before dispatch.** Frozen checks live under
   `docs/checks/`, freeze at one commit, then are read-only; a builder edit
   there is an automatic FAIL.
3. **Nobody grades their own work.** Builders report raw evidence. The
   check-runner grades every frozen RUN item; one fresh orchestrator-model
   subagent runs the final review — the loop's only model review. Never merge
   over a red checkrun; never skip the final review without a recorded ruling.
4. **The orchestrator writes implementation code only on a third strike**
   (loop.md `## Failure ladder`), graded like any builder's work. It never
   reads large diffs; read-only verification subagents do.
5. **Fresh builder per issue,** worktree-isolated. On blockers or wedged
   worktrees, answer durably and respawn from the issue and frozen check.
6. **Tier is set at decomposition** by config and dispatch rules. Failure
   never moves tier — failures are spec, context, or architecture problems.
7. **Builders never commit.** The orchestrator owns commits, merges, and
   closure, after checkrun evidence.
8. **Disagreement is mandatory.** PHASE 0 states the plan and every
   disagreement with file evidence, or what was checked before finding none.
9. **No silent fallback.** Record every precondition, blocker, missing tool,
   and sandbox limit; fix the input or route to a hard stop.

## Procedure

### 0. Ground

At every factory block boundary. Load `codebase-design` first and use its
glossary exactly — substitution is a defect.

- Read in authority order: `CLAUDE.md`/`AGENTS.md`, `README.md`, architecture
  docs, active spec, `docs/solutions/`, open issues, reports, checks, branches.
- Run `skills/architect/ground.ps1|.sh <run>` and rule on its typed exit: 0
  `GROUND: OK` proceeds — read its `FRONTIER:` line for the ready issues; 2
  `GROUND: STOP <which>` halts before dispatch; 3 `GROUND: DRIFT <fact>` is a
  tracker/git disagreement to rule on before continuing; 5 `GROUND: ERROR
  <why>` is a script/input error to fix. Detection only — it never posts,
  edits, or decides.
- Resolve models: `.architect/config`, then `~/.architect/config`, then
  dispatch.md `## Model alias table`. Verification subagents run at the
  builders model; the monitor is a script.

### 1. Intake

Explore, then ask at most ~5 questions in one batch — only where the answer
changes implementation or validation. Ask via the timed-ruling protocol;
timer-expired questions become recorded `## Assumptions` on the recommended
option.

In parallel, dispatch one read-only scout at the builders model
(`dispatch.md` `## Scout dispatch`); commit its map at
`docs/runs/<run>/map.md`. The map is planning-time input and expires at first
merge — builders get change-skeletons and interface contracts, never the map.

Preflight per tracker mode (`tracker.md` `## Preflight per mode`). Canary
each candidate backend once — list tools, `git log -1 --oneline`, reply
`CANARY: SHELLS_OK|DEGRADED`; on DEGRADED select the fallback backend and
record the substitution with evidence. Never switch backend mid-wave.

Write the spec with `to-spec`. Then one fresh orchestrator-model subagent
runs `adversarial-review` against the draft; apply surviving findings before
approval. Create the tracking issue — spec pointer, assumptions digest,
approve-by-comment instructions (`APPROVE`, `APPROVE with edits: <text>`,
`REJECT <reason>`), run marker, manifest path — then write the manifest (fix
ignore rules first if `docs/runs` is ignored).

### 2. Spec Approval

The one human step: the human edits or vetoes assumptions and approves or
rejects. Approval authorizes the whole issue plan; afterward, contact the
human only through tracking-issue digests or hard stops. Exactly three
forms, recorded verbatim in the spec, never inferred:

- In-session: explicit authorization, quoted.
- Tracking-issue: repo-owner comment `APPROVE` / `APPROVE with edits:` /
  `REJECT`.
- Timer: timed-ruling protocol expired silent → `APPROVE (auto, 5m silence)`
  plus reasoning, veto-able after the fact.

Timed-ruling protocol — every human question in the loop, present or not.
Never a blocking question UI (nothing times it out; an absent human hangs
the factory):

1. Print question, numbered options, recommended default in-session; mirror
   as a `RULING PENDING` tracker comment naming the default.
2. Arm ~5 minutes: detached background `sleep 300` whose exit wakes the loop
   (foreground sleep with raised timeout where background wakes don't exist).
3. Answer first: apply and kill the timer. Timer first: apply the default,
   record `RULING (auto, 5m silence): <decision> - <why>` on the tracker.
   Irreversible or destructive choices resolve silent to the non-destructive
   path; `docs/STOP` is absolute.

On approval, cut `factory/<run>`; every run commit lands there and main
stays untouched until the closing PR. One run per checkout — concurrent runs
each get their own worktree (`.architect/runs/<slug>`, machine-local).

### 3. Decompose

Compile the spec into dispatch-ready issues with `to-issues`: sub-issues
under the tracking issue, structural before behavioral with blocking edges,
tracer-bullet vertical slices, a file-disjoint parallel frontier, interface
contracts from producers, one compact change-skeleton per issue (a contract,
not a line mandate — PHASE 0 is the disagreement channel).

Write per-issue graded checks with `frozen-checks` under `docs/checks/<run>/`;
each issue links its check. Freeze preconditions: freeze committed on the
factory branch and pushed; `preflight.ps1`/`.sh` verifies worktree, freeze,
and a frozen-file spot-check; builders still FIRST-ACTION verify inputs.

Before the freeze commit, one fresh `adversarial-review` stress pass attacks
the whole decomposition — issues plus draft checks — and its surviving
findings land. Record freeze SHA, stress result, and plan on the tracking
issue. Re-planning is orchestrator-owned: diagnose, optionally fan out
researchers (`research.md`), amend spec/issue/checks in git and tracker,
respawn fresh. Builders never re-plan.

### 4. Factory Loop

Event loop: loop.md `## Factory block procedure`.

- Dispatch the ready issues — up to five build jobs plus one detection-only
  watchdog (`dispatch.md` `## Monitor dispatch`). Builders are Claude-native
  Agent-tool jobs (`architect-builder` def preloads `tdd` + `codebase-design`;
  model per alias table; codex backend by config). Every job end is a
  dispatch event: recompute the frontier and dispatch before grading — one
  completion routinely launches several builders.
- Sleep between events; wake on DONE, BLOCKED, stall/kill or watchdog
  evidence, or frontier recomputation.
- Status requests: run `skills/architect/status.ps1|.sh <run>`, print
  verbatim in a fenced block, never hand-compose the tree.
- DONE: write runner config, launch the check-runner in the background, rule
  on its typed exit — 0: commit evidence, merge through postflight; 2: commit
  failure evidence, enter the failure ladder; 5: recorded error rail.
  `POSTFLIGHT: OK` is the clean touch-set evidence.
- BLOCKED: answer on the issue with durable evidence; respawn fresh with the
  answer (`dispatch.md` `## Respawn-with-answer template`).
- Failure ladder (loop.md): (1) diagnose from checkrun or review evidence —
  never a large diff — respawn one fix builder with the answer; (2) fresh
  builder, deeper diagnosis; (3) third strike, Hard Rule 4.
- Post-freeze rulings are append-only in
  `docs/jobs/<run>/<issue-slug>-rulings.md` — PHASE-0 rulings, touch-set
  amendments, respawn answers. Orchestrator-owned, committed before merge,
  mirrored to the issue; the final review reads the file, not thread prose.
- Merge conflict = decomposition failure: kill the job, re-spec the graph.
- Calibrate open-ended reviews verbatim: "Flag only gaps that affect
  correctness, the stated requirements, or documented project invariants --
  cite file:line evidence for every finding. Do not report stylistic
  preferences."
- Record docs debt as it accrues; diagnoses, blocker answers, and
  what-did-not-work notes become `docs/solutions/<slug>.md` via the docs job.

### 5. Finish

Open with a timed-ruling question: run the final review? Default YES. On
YES, one fresh orchestrator-model subagent (MEDIUM effort, worktree from the
factory head) runs the `final-review` stage skill over the whole run diff:
edits directly, treats `docs/checks/` as read-only, keeps every graded RUN
item green, re-runs the full closing checkrun plus named suites, and is
green-or-discard — red review work never merges; discard whole and record
it. Merge green work through postflight; post verdict plus diffstat.

Then one dedicated builder docs job before the finish boundary — never the
orchestrator. Its dispatch block carries the change-context digest: shipped
issues with one-liners, diffstats, rulings and solutions pointers, domain
language changes. It consumes docs debt and updates product docs; its frozen
checks run through the check-runner and the orchestrator grades that
evidence directly (the final review has already run).

After the final review merges, or a recorded ruling skips it, dispatch one
integration subagent running the `integrate` stage skill. It owns remaining merges,
ship-time conflict resolution, PR prep or markdown-mode finish prep, and the
digest draft. The orchestrator rules on the result and posts the digest,
naming shipped, skipped, residual risks, and evidence.

## Hard Stops

Stop and ask the human when:

- `docs/STOP` exists in run or primary checkout, or an uncommitted
  `docs/runs/<run>/STOP` exists before dispatch.
- An irreversible or destructive action is needed.
- Two consecutive KILL decisions occur.
- A blocker collides with a recorded assumption.
- Scope grows beyond the approved spec.
- Required tracker preflight cannot be satisfied.

## Maintenance

Re-read against each new model generation; delete what models now do
unprompted — the Hard Rules are invariants, everything else is prunable.
Re-run `docs/evals/trigger-prompts.md` per generation. No feature ships
without evidence in `DESIGN.md`.
