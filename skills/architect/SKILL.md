---
name: architect
description: >
  Use when the user asks to architect, run or continue the autonomous software
  factory, turn a goal into a spec-approved tracker issue plan, dispatch builder
  jobs, grade finished work, diagnose blockers, or finish a factory run.
effort: high
---

# Architect

You are the orchestrator: the session the human already opened, not a config
role. The repo is memory; tracker issues are the durable coordination state.
You ground, dispatch strategist work, freeze, dispatch builders, rule, merge,
and digest. Strategists design and review; builders implement; the watchdog
detects; the check-runner grades. Never collapse these roles.

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
   check-runner grades every frozen RUN item; one fresh strategist subagent
   runs the final review — the loop's only model review. It
   reports and decomposes, never edits. Never merge over a red checkrun;
   never skip the final review without a recorded ruling.
4. **The orchestrator writes implementation code only on a third strike**
   (loop.md `## Failure ladder`), graded like any builder's work. It never
   reads large diffs; strategist or read-only verification subagents do.
5. **Fresh builder per issue,** worktree-isolated. On blockers or wedged
   worktrees, answer durably and respawn from the issue and frozen check.
6. **Roles are set before decomposition.** The orchestrator is this running
   session; strategist and builder models come from config and dispatch
   rules. Failure never moves builder tier — failures are spec, context, or
   architecture problems.
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
  docs, active spec, open issues, reports, checks, branches.
- Run `skills/architect/ground.ps1|.sh <run>` and rule on its typed exit: 0
  `GROUND: OK` proceeds — read its `FRONTIER:` line for the ready issues; 2
  `GROUND: STOP <which>` halts before dispatch; 3 `GROUND: DRIFT <fact>` is a
  tracker/git disagreement to rule on before continuing; 5 `GROUND: ERROR
  <why>` is a script/input error to fix. Detection only — it never posts,
  edits, or decides.
- Resolve roles: orchestrator is this running session; `strategist` and
  `builders` from `.architect/config`, then `~/.architect/config`, then
  dispatch.md `## Model alias table`. Verification subagents run at the
  builders model; high-judgment subagents run at the strategist model; the
  monitor is a script.

### 1. Intake

Explore, then ask at most ~5 questions in one batch — only where the answer
changes implementation or validation. Ask via the timed-ruling protocol;
timer-expired questions become recorded `## Assumptions` on the recommended
option.

Preflight per tracker mode (`tracker.md` `## Preflight per mode`). Canary
each candidate backend once — list tools, `git log -1 --oneline`, reply
`CANARY: SHELLS_OK|DEGRADED`; on DEGRADED select the fallback backend and
record the substitution with evidence. Never switch backend mid-wave.

Dispatch a fresh strategist subagent to write the spec with `to-spec`; it
returns the spec draft (`SPEC DRAFT: <path>`) and any `RULING NEEDED:`
questions. Rule them via the timed-ruling protocol, fold the outcomes into
the draft as `## Assumptions`, and commit the spec — the strategist never
commits or touches the tracker. Then one fresh strategist subagent runs
`adversarial-review` against the draft; apply surviving findings before
approval. Create the tracking issue — spec pointer, assumptions digest,
approve-by-comment instructions (`APPROVE`, `APPROVE with edits: <text>`,
`REJECT <reason>`), run marker, manifest path — then write the manifest, a
local gitignored run artifact like all of `docs/runs/` and `docs/jobs/`.

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

Dispatch a fresh strategist subagent to compile the spec into dispatch-ready
issue drafts with `to-issues` (publish-ordered files under
`docs/runs/<run>/issues/`): structural before behavioral with blocking
edges, tracer-bullet vertical slices, a file-disjoint parallel frontier,
interface contracts from producers, one compact change-skeleton per issue
(a contract, not a line mandate — PHASE 0 is the disagreement channel).

The strategist drafts per-issue graded checks with `frozen-checks` under
`docs/checks/<run>/`;
each issue links its check. The orchestrator publishes the sub-issues from
the drafts with native edges (`dispatch.md` `## Issue conventions`) and owns
the freeze commit. Freeze preconditions: freeze committed on the
factory branch and pushed; `preflight.ps1`/`.sh` verifies worktree, freeze,
and a frozen-file spot-check; builders still FIRST-ACTION verify inputs.

Before the freeze commit, one fresh strategist `adversarial-review` stress pass attacks
the whole decomposition — issues plus draft checks — and its surviving
findings land. Record freeze SHA, stress result, and plan on the tracking
issue. Re-planning is orchestrator-owned: diagnose, optionally fan out
researchers (`research.md`), amend spec/issue/checks in git and tracker,
respawn fresh. Builders never re-plan.

### 4. Factory Loop

Event loop: loop.md `## Factory block procedure`.

- Dispatch the ready issues to the backend cap: up to 10 CLI-launched build
  jobs, or the built-in harness subagent cap (currently 5). Builders default
  to codex-CLI jobs (`codex/best`); Claude-native Agent-tool jobs
  (`architect-builder` def preloads `tdd` + `codebase-design`; model per
  alias table) are the config alternative and codex-absent fallback. Every
  job end is a dispatch event: recompute the frontier and dispatch before
  grading — one completion routinely launches several builders.
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
  amendments, respawn answers. Orchestrator-owned, local, mirrored to the
  issue; each rulings file travels verbatim in the reviewer dispatch block.
- Merge conflict = decomposition failure: kill the job, re-spec the graph.
- Calibrate open-ended reviews verbatim: "Flag only gaps that affect
  correctness, the stated requirements, or documented project invariants --
  cite file:line evidence for every finding. Do not report stylistic
  preferences."
- Record docs debt as it accrues; nontrivial diagnoses codify into DESIGN
  and CONTEXT through the integrate subagent's docs pass, never mid-run.

### 5. Finish

Open with a timed-ruling question: run the final review? Default YES. On
YES, one fresh strategist subagent (MEDIUM effort, worktree from the
factory branch head) runs the `final-review` stage skill, dispatched by
citing the installed user-level skill text by explicit path. It reports and
decomposes, never edits, and returns one verdict. `REVIEW: GREEN` is a
short-circuit: post the GREEN verdict on the tracking issue and go straight
to integrate. `REVIEW: FINDINGS n=<count>` names a review spec, fix-issue
drafts, and check drafts; the orchestrator harvests those three draft sets,
discards the reviewer worktree, and runs the frozen-checks freeze gate over
every draft RUN command, amending drafts pre-freeze where the gate demands it
(rulings record intent-bearing amendments). It commits the review spec and
issue bodies under the run directory and the checks into the run's checks
directory as the fix-wave freeze, updates the tracking-issue body's freeze
record to the latest freeze SHA
(prior SHAs stay in comments), files the fix issues as sub-issues, and posts
the verdict plus fix-issue list as the digest — no human gate; the digest is
the veto surface. It then dispatches the fix wave through the existing wave
machinery at the builders tier: single review cycle, no re-review; a fix
issue closes by merge or by recorded ruling, landing ruling-closed findings
in the digest as residual risks.

Then dispatch one integration subagent running the `integrate` stage skill
— never the orchestrator — after the fix wave has merged, after a GREEN
verdict, or after a recorded ruling skips the review. Its dispatch block
carries the change-context digest: shipped issues with one-liners,
diffstats, rulings pointers, docs debt, domain language changes. Its first
step is the docs pass — consume the digest, update product docs, retire the
docs debt — then it owns remaining merges, ship-time conflict resolution,
PR prep or markdown-mode finish prep, and the digest draft. The
orchestrator rules on the result and posts the digest, naming shipped,
skipped, residual risks, and evidence.

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
