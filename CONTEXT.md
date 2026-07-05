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
- **Judge** - a fresh-context, read-only intent reviewer for one issue. The
  deterministic check-runner grades frozen RUN items first; the judge checks
  integrity, diff-vs-intent, and one graded RUN spot-check. Not a config key.
- **Watchdog** - a deterministic script that sweeps in-flight jobs and exits
  with typed evidence (`ALL_DONE`, `INTEGRATED`, `STALL`, `REPEAT`). It never
  kills, nudges, or decides; the orchestrator rules on the evidence. A job is
  done only when its report's final non-blank line starts with `STATUS:`.
- **Monitor** - informal name for the watchdog. Historically an LLM subagent;
  now only a fallback template for harnesses without background-exit
  notifications.
- **Stress-test** - a fresh adversarial reviewer of the decomposition before
  the freeze: attacks check commands, issue bodies, and repo reality.
- **Scout** - a researcher-shaped investigator: reads, researches, reports;
  may not modify code. Build runs commit a scout map before decomposition.

## Units of work

- **Issue** - one vertical-slice unit of work, one GitHub issue, one builder
  job. Body carries what-to-build, acceptance criteria, boundaries (disjoint
  file sets), a change-skeleton, and interface handoff blocks.
- **Tracking issue** - the run's parent issue: dashboard, digest, and
  preflight record. Sub-issues hang off it with native blocked-by edges.
- **Plan** - the issue set plus native blocked-by links. The schedulable set is
  always the ready issues, dispatched up to five jobs at once.
- **Wave** - one ready-issue dispatch: its jobs plus one watchdog.
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
  respawn answers. Part of the judge's intent context.
- **Verdict comment** - the judgment record posted on the issue: runner
  summary, checks integrity, diff-vs-intent, the spot-check result, and the
  slice call.
- **Sync judge** - a harness-native judge dispatched with
  `run_in_background: false`, so the verdict returns as the tool result.
- **Recovery ladder** - the ordered rescue path for a missing background
  deliverable: retrieve task output, nudge once, then discard and respawn
  fresh. The orchestrator never authors a missing verdict.
- **Close-out** - stopping or closing a consumed subagent or background shell
  task in the same turn its result or typed exit was consumed.
- **Closing review** - the human-gated review-and-fix pass after build issues
  close and before docs-finish. It uses the orchestrator tier and is
  green-or-discard.
- **Canary** - the preflight spawn that proves a builder backend actually has
  working tools before the decomposition records it.
- **Change-context digest** - the shipped-issues, diffstat, rulings,
  docs-debt, and domain-language summary passed to the builder-run docs finish
  job.
- **Config vocabulary** - flat `.architect/config` keys include
  `tracker = github | markdown`, `orchestrator = cli/model`,
  `builders = cli/model:effort`, and optional
  `when -> cli/model:effort - why` dispatch rules. Absent `tracker =` means
  GitHub mode; absent builder routing means tier-down default.
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
- **grill** -> **stress-test**.
- **frontier** -> **ready issues**.
- **stop rail** -> **hard stop**.
- **Handoff / `docs/HANDOFF.md`** - v3/v4 repo-memory diary; retired in v5.
  The tracker and git are the memory.
- **Judgment ledger** - the handoff section that recorded verdicts; replaced
  by verdict comments on issues.
- **Heartbeat** - the v4 orchestrator stall-check; replaced by the watchdog.
- **LLM monitor sweep** - replaced by the watchdog script. The fallback
  template remains in `dispatch.md`.
- **Slice / block** - v4's unit and iteration names; v5 says issue and
  factory-loop event.
- **Sentinel / `LOOP:` line** - v3 driver-control protocol; deleted in v4.
- **Driver** - the v3 external loop script (`bin/architect-loop.*`); deleted
  in v4. The loop is the orchestrator conversation itself.
- **PRD** - renamed to **spec** (2026-07-02). "PRD" is retired; "spec" is the
  current term everywhere the loop refers to a specification document.
