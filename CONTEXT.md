# CONTEXT - ubiquitous language for architect-loop

Glossary only. No implementation details, no spec content.

## Roles

- **Orchestrator** - the single interactive session the human opens (any
  harness, any surface). Grounds, runs intake, decomposes, freezes,
  dispatches, arbitrates, diagnoses, integrates. Never writes implementation
  code, never reads large diffs, never judges checks.
- **Orchestrator tier** - the model tier used for orchestration and designated
  high-judgment reviews: a capability level, not one process.
- **Builder** - a fresh-context worker agent that implements exactly one issue
  in an isolated worktree. Cannot commit. The builder tier is typically
  cheaper than the orchestrator tier and never changes because a job failed.
- **Judge** - retired (human-directed ruling 2026-07-06; removed from
  `skills/architect/**` by the skill-library run, issue #118). Was the
  per-issue fresh-context, read-only intent reviewer for one issue.
  Current-flow descriptions in product docs read builders run own tests ->
  check-runner grades frozen checks -> closing cohesion review before the
  PR; do not present the per-issue judge as a current-flow step. The judge
  templates remain in `dispatch.md`, marked RETIRED, for optional read-only
  verification dispatches. Not a config key.
- **Watchdog** - a deterministic script that sweeps in-flight jobs and exits
  with typed evidence (`ALL_DONE`, `INTEGRATED`, `STALL`, `REPEAT`). It never
  kills, nudges, or decides; the orchestrator rules on the evidence. A job is
  done only when its report's final non-blank line starts with `STATUS:`.
- **Monitor** - informal name for the watchdog. Historically an LLM subagent;
  now only a fallback template for harnesses without background-exit
  notifications.
- **Stress-test** - Target 2 of `/adversarial-review`: a fresh reviewer
  attacks the frozen-but-not-yet-dispatched decomposition (check commands,
  issue bodies, repo reality) before the freeze is authorized. Target 1 of
  the same skill is the pre-decomposition spec review.
- **Scout** - a researcher-shaped investigator: reads, researches, reports;
  may not modify code. Build runs commit a scout map before decomposition.

## Units of work

- **Issue** - one vertical-slice unit of work, one GitHub issue, one builder
  job. Body carries what-to-build, acceptance criteria, boundaries (disjoint
  file sets), a change-skeleton, and interface handoff blocks.
- **Fix issue** - one issue cut from a review spec: same body shape,
  boundaries, and frozen check as a build issue, dispatched at the builders
  tier in the fix wave.
- **Slice** - the vertical cut an issue implements: narrow but complete
  end-to-end. Slice names the cut, issue names its tracker record - same
  unit, two angles (`skills/codebase-design/SKILL.md` glossary). Live
  vocabulary again as of the skill-library run; see Retired terms for the
  earlier "v4 unit name" framing this reconciles.
- **Tracking issue** - the run's parent issue: dashboard, digest, and
  preflight record. Sub-issues hang off it with native blocked-by edges.
- **Plan** - the issue set plus native blocked-by links. The schedulable set is
  always the ready issues, dispatched up to five jobs at once.
- **Wave** - one ready-issue dispatch: its jobs plus one watchdog.
- **Fix wave** - the parallel builder dispatch that implements a review spec;
  the run's final wave, graded by the check-runner like any other.
- **Review cycle** - one final review plus its fix wave; exactly one per run.
- **Factory run** - everything between spec approval and the closing PR; runs
  unattended on the factory branch (`factory/<run>`), with an optional
  human-gated closing review before docs-finish.

## Control & Memory

- **Tracker** - the selected coordination state. GitHub mode uses GitHub
  issues; markdown mode uses git-tracked `docs/issues/` markdown files. Both
  modes have the same semantics: claims are assignments, progress and
  verdicts are comments, the tracking issue carries the digest, and all
  mutations are orchestrator-executed. "Not in the tracker = didn't happen."
- **Status tree** - a read-only render over run artifacts and the tracker;
  never a new state store.
- **Spec approval** - the one human step: review one spec document, edit or
  veto its recorded assumptions, approve in-session or by commenting
  `APPROVE` on the tracking issue. Verbatim pre-approval can authorize a run
  at invocation; otherwise the factory waits about 5 minutes, rules with the
  orchestrator's best judgment, records the ruling for after-the-fact veto,
  and continues. Irreversible or destructive silence takes the non-destructive
  path; `docs/STOP` remains absolute.
- **Check** - a frozen, committed, exact acceptance check
  (`docs/checks/<issue-slug>.md`). Read-only for everyone once frozen. RUN
  items are graded by machine-readable expectations.
- **Graded RUN** - a check RUN item with `-> exit:<n>` and optional fixed
  stdout `match:"substring"` expectation. Runner exits are typed: 0 all pass,
  2 any expectation fails, 5 runner error.
- **Scout map** - the committed `docs/runs/<run>/map.md` file: file:line
  anchors, conventions, testing seams, and gotchas gathered before
  decomposition.
- **Change-skeleton** - a compact per-issue structure block naming files,
  signatures, data flow, and invariants. It proves ownership and parallelism;
  it is not implementation code.
- **Freeze commit** - the commit that locks a run's checks; it is pushed before
  any dispatch, and worktrees are verified against it after spawn.
- **Rulings file** (`docs/jobs/<issue-slug>-rulings.md`) - orchestrator-owned,
  append-only post-freeze intent: PHASE-0 rulings, boundary amendments,
  respawn answers. Read by the closing review instead of thread prose.
- **Verdict comment** - the grading record posted on the issue at close:
  checkrun summary plus typed exit, postflight result, and the slice call
  with its decisive reason. The closing review's run-level verdict goes on
  the tracking issue.
- **Sync dispatch** - dispatching a result-bearing subagent (closing review,
  scout, adversarial review, optional verification) with
  `run_in_background: false`, so the result returns as the tool result.
- **Recovery ladder** - the ordered rescue path for a missing background
  deliverable: retrieve task output, nudge once, then discard and respawn
  fresh. The orchestrator never authors a missing result.
- **Close-out** - stopping or closing a consumed subagent or background shell
  task in the same turn its result or typed exit was consumed.
- **Review spec** - the reviewer-authored spec at the finish boundary:
  verified findings as requirements, each carrying severity and its
  verification. Input to fix-issue decomposition; a run artifact, not
  human-approved.
- **Closing review** - the human-gated review-and-decompose pass after build
  issues close and before docs-finish. It uses the orchestrator tier, is
  read-only over product code and tests, and on findings writes a review spec
  cut into fix issues for the fix wave; zero findings short-circuits to a
  GREEN verdict.
- **Canary** - the preflight spawn that proves a builder backend actually has
  working tools before the decomposition records it.
- **Change-context digest** - the shipped-issues, diffstat, rulings,
  docs-debt, and domain-language summary passed to the builder-run docs finish
  job.
- **Config vocabulary** - flat `.architect/config` keys include
  `tracker = github | markdown`, `orchestrator = cli/model`,
  `builders = cli/model:effort`, and optional
  `when -> cli/model:effort - why` dispatch rules. Absent `tracker =` means
  GitHub mode; absent builder routing means the `codex/best` default.
- **Post-flight** - the orchestrator's mechanical checks on a completed job
  (boundaries, check-file integrity, raw-only report, status-line form) before
  integration. Distinct from judgment.
- **Codify** - the compound step: nontrivial diagnoses become durable product
  documentation, usually DESIGN for evidence and CONTEXT for vocabulary. Raw
  run artifacts still live under `docs/jobs/` while a run is active.
- **docs/STOP** - the kill switch; its presence halts the factory before the
  next dispatch.

## Retired terms (historical; appear in pre-v5 docs and git history)

- **gate** -> **check**.
- **DAG** -> **the plan** / issues linked with blocked-by.
- **cold** -> **fresh**.
- **epic** -> **tracking issue**.
- **brain** -> **orchestrator**.
- **brawn** -> **builders**.
- **lane** -> **job**.
- **grill** -> **adversarial-review** (Target 1: spec review, pre-decomposition).
- **frontier** -> **ready issues**.
- **stop rail** -> **hard stop**.
- **Handoff / `docs/HANDOFF.md`** - v3/v4 repo-memory diary; retired in v5.
  The tracker and git are the memory.
- **Judgment ledger** - the handoff section that recorded verdicts; replaced
  by verdict comments on issues.
- **Heartbeat** - the v4 orchestrator stall-check; replaced by the watchdog.
- **LLM monitor sweep** - replaced by the watchdog script. The fallback
  template remains in `dispatch.md`.
- **Block** - v4's iteration name; v5 says factory-loop event. (**Slice** is
  no longer retired: the skill-library run's codebase-design glossary
  reinstated it as the vertical cut an issue implements - see Units of work,
  Issue entry.)
- **Sentinel / `LOOP:` line** - v3 driver-control protocol; deleted in v4.
- **Driver** - the v3 external loop script (`bin/architect-loop.*`); deleted
  in v4. The loop is the orchestrator conversation itself.
- **PRD** - renamed to **spec** (2026-07-02). "PRD" is retired; "spec" is the
  current term everywhere the loop refers to a specification document.
- **green-or-discard** -> per-issue isolation via the fix wave (review-fanout
  run, 2026-07-06, issue #137). The closing reviewer no longer edits the run
  diff or discards its whole pass on one red change; verified findings become
  fix issues, and a failed fix is isolated to its own issue.
- **review branch** - retired the same run; the closing review works in its
  own worktree and never opens a branch of its own.
