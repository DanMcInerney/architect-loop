# Spec: Architect v5 — the autonomous software factory

Status: DRAFT — awaiting human review at the spec gate (the one human step).
Author: brain session, 2026-07-02. Research basis:
`docs/research/autonomous-software-factory.md` (e9d6665) and
`docs/research/skill-prompt-patterns.md` (r4 pass: compound engineering,
superpowers, Pocock design skills, gstack local mining).

## Problem

The v4 loop is interactive per slice: the human is present at every block
boundary, HANDOFF.md is the coordination state, and parallelism is bounded by
the one-slice-per-block rhythm. The human wants: describe the goal, answer at
most a handful of questions, review one spec document, then walk away while
the work runs to completion — parallel where possible, with the brain
handling every judgment call and brawn agents doing all coding.

## Solution (one paragraph)

v5 replaces the per-slice interactive loop with a three-stage flow: **intake**
(brain asks ≤5 materiality-gated questions in one batch, writes a spec with a
recorded Assumptions section), **spec gate** (the single human review/veto
step), and the **factory loop** (brain decomposes the spec into a GitHub
issue DAG, freezes gates in git, then dispatches up to 5 cold brawn worktree
lanes on the unblocked frontier plus one cheap detection-only monitor
subagent; the brain sleeps between events and wakes only to judge, diagnose
failures, answer blockers, merge, and dispatch the next frontier, until every
issue is closed). GitHub issues replace HANDOFF.md as coordination state; git
keeps specs and frozen gates.

## User story

"I tell /architect what I want, answer as few questions as possible, review
one spec doc, and the skill runs the work until it is fully completed —
answering subagent questions, making sure subagents don't stall — with up to
5 subagents at once, brawn writing progress to GitHub issues."

## Design decisions (each traceable to research or human ruling)

### D1. Roles

- **Brain** (frontier, the running session): intake, spec, decomposition,
  gate authoring + freeze, PHASE-0 disagreement rulings, blocker answers,
  failure diagnosis, judging (via cold brain-tier judge subagents), merging,
  the final digest. The brain never writes implementation code and never
  reads large diffs directly (verifier/judge subagents do). The brain IS the
  middle manager; no intermediate manager agent (harness depth limits forbid
  it and it re-adds MAST coordination-failure surface).
- **Brawn** (configurable, default same-family tier-down): coding only, in
  cold worktree-isolated lanes, one issue per lane per session.
- **Monitor** (cheapest tier, e.g. haiku:low): detection only — see D6.
- **Judge** (brain tier, cold): frozen-gate verdicts, unchanged from v4.

### D2. Model config

Existing `.architect/config` chain is unchanged and sufficient:
`brain = <cli>/<spec>[:effort]`, `brawn = ...`, optional `when <class> ->
<tier>` dispatch rules. Default brawn = same-family tier-down. Example the
human named: `brain = claude (Fable session)`, `brawn = codex/best:xhigh`.
**Human ruling (2026-07-02): NO automatic tier movement.** Tier-up-over-retry
is removed from the skill text. Tier is set at decomposition (config +
dispatch rules) and never changes on failure; failures are spec/context
problems the brain fixes (D7).

### D3. Intake

- Brain explores the repo + request, then asks **at most ~5 questions in ONE
  batch**, each passing the materiality test: *would the answer change
  implementation or validation strategy?* (Spec Kit /clarify pattern.)
- Everything below the bar is decided and recorded in the spec's
  `## Assumptions` section — one line each, human-vetoable at the gate.
- Unanswered questions (human AFK) auto-convert to recorded assumptions
  using the brain's recommended option.
- Preflight (hard preconditions, fail loudly, no fallbacks): GitHub remote
  exists; `gh auth status` passes; `gh` ≥ 2.94.0 (native `--blocked-by` /
  `--parent` / `--blocking` flags).

### D4. Spec gate (the one human step)

Human reads `docs/spec/<project>.md`, edits/vetoes assumptions, approves.
Approval authorizes the entire DAG — it replaces v4's 10-slice unattended
counter as the authorization boundary. After approval the human is contacted
only via the batched digest (D8) or the stop rails (D11).

### D5. Decomposition

- Brain compiles the approved spec into GitHub issues: one **epic** issue
  (project dashboard; replaces HANDOFF.md's TL;DR role), sub-issues per
  vertical slice (`gh` native parent links), dependency edges via native
  blocked-by. Issue body: What to build / Acceptance criteria / Boundaries
  (may-touch / must-not-touch file sets) / link to frozen gate file.
- Parallelism is designed here: file-touch sets of concurrently schedulable
  issues MUST be disjoint; dependency edges only where real. The schedulable
  set is always the unblocked frontier of the DAG.
- **Gates stay in git** (`docs/gates/<issue-slug>.md`), frozen at one commit;
  issues link to them. Tamper-evidence check
  (`git diff <freeze-sha>..HEAD -- docs/gates/`) is retained verbatim from v4.
- **One grill pass over the whole decomposition** (not per-issue): a cold
  read-only subagent attacks all gate files + the DAG (touch-set overlaps,
  phantom/missing dependencies, non-falsifiable criteria, repo-name grep
  collisions) before the freeze commit.
- Brawn-authored tests never count as gates by themselves (80.2% weak-oracle
  finding); gates are brain-authored commands; judge scrutinizes any new
  test's assertions, not just its exit code.

### D6. Monitoring (human-ruled design, 2026-07-02)

- **No per-command kill ceilings.** Long test suites are legitimate.
  Spec/issue may carry duration *hints* ("full suite ≈ 20m") so the monitor
  doesn't flag early. Liveness = output growth + process activity, not
  wall-clock.
- One **detection-only monitor subagent** (cheapest tier) dispatched with
  each factory wave. Loop: every ~10 min sweep each in-flight lane — report/
  output file growth since last sweep, process-tree existence/activity,
  tail-of-output repeat-command check. All healthy → keep looping. All lanes
  done → exit quietly. Anomaly → **exit immediately with an evidence report**
  (lane id, minutes since last growth, tail excerpt, process state). The
  monitor's exit is the brain's wake-up (background-subagent completion
  notification) — the brain never polls.
- The monitor never kills, never nudges, never decides. The brain reads the
  evidence and rules: healthy-long-run (redispatch monitor, sleep) / needs
  nudge or answer / wedged (kill lane, discard worktree, respawn from frozen
  spec with route-around).
- Codex backend note: `max_threads` 6 → 5 lanes + 1 monitor is exactly at
  cap; record in dispatch.md.

### D7. Failure and blocker handling

- **Blocker**: brawn posts `BLOCKED: <exact blocker> + what I tried` as an
  issue comment and exits (a blocker IS a completion event). The brain
  answers on the issue (durable log) and respawns a fresh brawn with the
  answer in the spawn context (delivery). Respawn-over-resume is the default;
  same-session messaging only when the harness supports it and context is
  young.
- **Gate failure**: judge FAILs → brain diagnoses from evidence (not the full
  diff), fixes the *input* (issue text, forbidden-pattern note, missing
  context), respawns same-tier. Second failure on the same issue after a
  brain intervention → brain re-decomposes the issue or escalates to digest.
  No automatic tier change (D2).
- Merge conflict = decomposition failure: KILL the conflicting lane, re-spec;
  never hand-resolve builder conflicts (v4 rule retained).

### D8. Communication

- Brawn writes to the issue: PHASE-0 disagreements, milestone/blocker/done
  comments only (never per-commit; GitHub secondary rate limits, 65k cap).
  Where a backend sandbox blocks network/gh, the lane report file is
  mirrored to the issue comment by the dispatch tooling — same log, no
  sandbox exception.
- Brain writes to the issue: rulings, blocker answers, judge verdict +
  evidence on close.
- Epic issue carries the batched **escalation digest**: anything the spec
  genuinely doesn't answer, batched; plus the end-of-run summary.
- A running brawn agent does NOT re-read issue comments (Copilot precedent);
  the issue is the log, the spawn context is the delivery channel.

### D9. Design-quality doctrine (the brain's design rubric)

Applied at spec time and decomposition time — design quality is enforced
with named, checkable rules at plan time, never requested with adjectives at
review time. Full evidence: `docs/research/skill-prompt-patterns.md`.

- **The oddity rule** (root-cause design over patching): when reality
  resists the plan — an oddity, workaround, or special case — the brain
  classifies before any fix is dispatched: (a) local wart → patch it,
  record it on the issue; (b) a variation that will recur (e.g. the next
  benchmark added to a zoo) → a real seam exists → emit a structural issue
  that abstracts it, blocking the behavioral issue. Guardrail against
  over-abstraction: "don't introduce a seam unless something actually
  varies across it — one adapter is a hypothetical seam, two is a real
  one." Three failed fixes on the same point = stop and question the
  architecture, never attempt fix #4.
- **Tidy-first DAG structure** (Beck: "make the change easy, then make the
  easy change"): structural (behavior-preserving) and behavioral changes
  are SEPARATE issues with a blocking edge, never mixed in one lane.
  Structural-issue gates = existing tests still green.
- **Deep modules + design it twice**: the spec names its fundamental
  abstractions. Each NEW load-bearing abstraction (a module other issues
  build on) gets 2-3 radically different interface sketches from cheap
  parallel subagents; the brain picks with recorded rationale, judged on
  depth-as-leverage (small interface hiding real complexity), the deletion
  test, and misuse-resistance. Leaf code never triggers this.
- **Interface handoff blocks**: any issue producing a surface another issue
  consumes states that interface verbatim (names, parameters, return types)
  in its body; the consumer references it. Disjoint files keep lanes from
  colliding; interface blocks make them compose.
- **TDD discipline (per Pocock's tdd skill)**: no test is written at an
  unconfirmed seam — the spec's Testing-seams section and the issue body
  confirm seams upfront, so brawn never stops to ask mid-lane. Tests
  describe behavior through public interfaces only and must survive an
  internal refactor. Tracer-bullet vertical slices: one test → one
  implementation, never all-tests-then-all-code (the horizontal-slice
  anti-pattern produces tests of imagined behavior). Never refactor while
  RED; refactoring happens on green — and structural work belongs in
  structural issues (tidy-first, above), not inline. You can't test
  everything: each issue names the behaviors that matter most.
- **Codify (compound) step**: nontrivial diagnoses — a blocker the brain
  solved, an oddity ruling, a what-didn't-work — become
  `docs/solutions/<slug>.md` (Problem / What Didn't Work / Why This Works /
  Prevention) via the docs lane at the PR boundary; intake grounding reads
  `docs/solutions/` so each run makes the next one easier.
- **Reviewer calibration** (verbatim in judge/cross-review prompts): "Flag
  only gaps that affect correctness, the stated requirements, or documented
  project invariants — cite file:line evidence for every finding. Do not
  report stylistic preferences."
- **Domain language, sparse ADRs**: issues and interfaces use the project's
  domain terms (update the glossary the moment a term sharpens). ADR only
  when hard-to-reverse AND surprising-without-context AND a real trade-off.
- **Parallel-safety check beyond files**: concurrently schedulable issues
  must also not share migrations, lockfiles, generated artifacts,
  config/schema, dev servers, or databases.

### D10. Skill-writing craft (applies to building v5's own text)

Descriptions state when to use + trigger branches, never summarize the
workflow. Every step ends on a checkable completion criterion. Progressive
disclosure: SKILL.md top stays legible, reference lives in dispatch/loop
files. No-op pruning test per line ("does this line change behaviour versus
the default?"). The 800-non-blank-line guard stands (compound-engineering's
36k-token always-loaded footprint is the documented failure case).

### D11. Safety rails (v4 rails, retargeted)

`docs/STOP` before any dispatch wave; irreversible/destructive actions stop
immediately; two consecutive KILLs stop the factory; a blocker that collides
with a recorded assumption goes to the human (it is a spec-gate decision
surfacing late); builders never commit (brain owns commits/merges); builders
touching `docs/gates/` = automatic FAIL; brain-tier cold judge on every
issue; scope growth beyond the approved spec stops the factory.

## What changes in this repo (deliverable inventory)

1. `skills/architect/SKILL.md` — rewritten: v5 procedure (intake → gate →
   decompose → factory loop), hard rules retargeted to issues, D9
   design-quality doctrine embedded in the spec/decompose steps (oddity
   rule, tidy-first issue splitting, design-it-twice trigger, interface
   handoff blocks, codify step to `docs/solutions/`).
2. `skills/architect/loop.md` — rewritten as the factory-loop reference:
   event-driven block procedure, monitor protocol, failure/blocker ladders,
   digest format; judgment ledger becomes issue verdict comments; slice
   counter replaced by DAG authorization boundary.
3. `skills/architect/dispatch.md` — updated: monitor dispatch template +
   agent def, respawn-with-answer template, issue comment conventions +
   exact `gh` commands, tier-up-over-retry text REMOVED, timeout-ceilings
   section rewritten to duration-hints + liveness signals, codex
   max_threads note.
4. `.claude/agents/architect-monitor.md` — new detection-only agent def
   (cheapest tier; read-only + shell for file/process checks).
5. `.claude/agents/architect-builder.md`, `architect-judge.md` — updated for
   issue-based reporting (lane report file remains the raw-evidence artifact;
   issue comment is the mirror).
6. `skills/architect/HANDOFF.template.md` — deleted. HANDOFF.md references
   removed from all skill text.
7. Installers re-run (Claude + Codex trees), same source-copy discipline.
8. Docs debt (one dedicated lane at the PR boundary): README v5 usage,
   DESIGN.md new section with this spec's evidence trail.
9. Existing GitHub issue #2 (model config) — absorbed by D2; close with a
   pointer at decomposition time.

## Testing decisions (seams)

- Skill text changes are verified by the loop's own gates: grep-based
  invariant checks (no `HANDOFF.md` references outside historical docs; no
  `tier-up` text), installer-tree sync checks, and a live canary: one
  end-to-end dogfood wave on this repo (real issues, ≥2 parallel lanes,
  monitor dispatched, one induced blocker exercising respawn-with-answer).
- The dogfood run of THIS spec is itself the acceptance test of the process.

## Out of scope

- Local/non-GitHub tickets backend (Pocock dual-mode) — rejected assumption A2.
- Middle-manager agent layer, merger agent, Agent Teams substrate (revisit
  when teams exit experimental + gain worktree isolation).
- Automatic tier escalation of any kind.
- CI/merge-queue integration beyond existing PR discipline.
- Cross-repo factories; one repo per factory run.

## Assumptions (human-vetoable at this gate)

- **A1 (unanswered intake Q1)**: v5 FULLY REPLACES v4 — one flow, HANDOFF
  machinery deleted, git history preserves v4. No coexist mode.
- **A2 (unanswered intake Q2)**: GitHub remote + gh auth + gh ≥ 2.94.0 are
  hard preconditions; fail loudly; no local fallback backend.
- **A3 (unanswered intake Q3)**: dogfood by hand-running the v5 process to
  build v5 itself (brain = this session, real issues on this repo, brawn
  lanes, monitor), rather than building v5 via the v4 loop.
- **A4 (unanswered intake Q4)**: dogfood brawn = `claude/tier-down`
  (sonnet:high) under the Fable brain; judgment-heavy issues may be routed
  by an explicit dispatch rule, recorded in config, not by failure.
- **A5**: `gh` on this machine is upgraded to ≥ 2.94.0 before decomposition
  (2.88.0 installed; native dependency flags require 2.94.0).
- **A6**: issue slugs reuse the slice-name conventions; `docs/lanes/` raw
  reports remain the builder's primary artifact, mirrored to issues.
- **A7**: the 800-non-blank-line skill-text size guard and ≤~400-changed-
  lines slice discipline from loop-hardening still apply to v5's own build.

## Clarifications (Q→A, from the 2026-07-02 session)

- Q: tier-up-over-retry? → A: **No.** Brain diagnoses failures; tier never
  moves automatically.
- Q: per-command timeout kill ceilings? → A: **No.** Duration hints +
  liveness-based detection; a cheap monitor subagent sweeps every ~10m,
  detection-only, and its exit-with-evidence wakes the brain to decide.
- Q: middle manager as separate agent? → A: No — the brain is the middle
  manager; the pattern's discipline is adopted, the extra layer is not.
- Q: coordination state? → A: GitHub issues (non-negotiable), gates/specs in
  git; HANDOFF.md retired.
- Q: parallelism? → A: up to 5 brawn lanes on the DAG frontier + 1 monitor.
- Q: brain/brawn split? → A: brain = spec, decomposition, review, problem
  solving; brawn = all coding. Frontier brain, configurable brawn,
  same-family tier-down default (non-negotiable).
- Q: scope-challenge rubric in D9? → A: **removed** (human ruling
  2026-07-02).
- Q: TDD lesson source? → A: **Pocock's tdd skill, not superpowers**
  (human ruling 2026-07-02). Superpowers' RED/GREEN evidence artifact
  dropped; its enforcement role is covered by seams-confirmed-in-spec,
  the judge's assertion scrutiny of brawn-authored tests, and gates rerun
  cold at judgment.
