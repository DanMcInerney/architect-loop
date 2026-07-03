# CONTEXT - ubiquitous language for architect-loop

Glossary only. No implementation details, no spec content.

## Roles

- **Orchestrator** - the single interactive session the human opens (any
  harness, any surface). Grounds, runs intake, decomposes, freezes,
  dispatches, arbitrates, diagnoses, integrates. Never writes implementation
  code, never reads large diffs, never judges checks.
- **Orchestrator tier** - the model tier used for orchestration and judgment:
  a capability level, not one process.
- **Builder** - a fresh-context worker agent that implements exactly one issue
  in an isolated worktree. Cannot commit. The builder tier is typically
  cheaper than the orchestrator tier and never changes because a job failed.
- **Judge** - a fresh-context, read-only agent at orchestrator tier that runs
  an issue's frozen checks and returns verdicts with raw evidence. Same
  capability as the orchestrator, none of its conversation. Not a config key.
- **Watchdog** - a deterministic script that sweeps in-flight jobs and exits
  with typed evidence (`ALL_DONE`, `INTEGRATED`, `STALL`, `REPEAT`). It never
  kills, nudges, or decides; the orchestrator rules on the evidence.
- **Monitor** - informal name for the watchdog. Historically an LLM subagent;
  now only a fallback template for harnesses without background-exit
  notifications.
- **Stress-test** - a fresh adversarial reviewer of the decomposition before
  the freeze: attacks check commands, issue bodies, and repo reality.
- **Scout** - a researcher-shaped investigator: reads, researches, reports;
  may not modify code.

## Units of work

- **Issue** - one vertical-slice unit of work, one GitHub issue, one builder
  job. Body carries what-to-build, acceptance criteria, boundaries (disjoint
  file sets), and interface handoff blocks.
- **Tracking issue** - the run's parent issue: dashboard, digest, and
  preflight record. Sub-issues hang off it with native blocked-by edges.
- **Plan** - the issue set plus native blocked-by links. The schedulable set is
  always the ready issues, dispatched up to five jobs at once.
- **Wave** - one ready-issue dispatch: its jobs plus one watchdog.
- **Factory run** - everything between spec approval and the closing PR; runs
  unattended on the factory branch (`factory/<run>`).

## Control & Memory

- **Tracker** - GitHub issues are the coordination state: claims are
  assignments, progress and verdicts are comments, the tracking issue carries
  the digest. "Not in the tracker = didn't happen."
- **Spec approval** - the one human step: review one spec document, edit or
  veto its recorded assumptions, approve in-session or by commenting
  `APPROVE` on the tracking issue. Verbatim pre-approval can authorize a run
  at invocation; otherwise the factory parks with reminders and fails safe
  after 7 days.
- **Check** - a frozen, committed, exact acceptance check
  (`docs/checks/<issue-slug>.md`). Read-only for everyone once frozen.
- **Freeze commit** - the commit that locks a run's checks; it is pushed before
  any dispatch, and worktrees are verified against it after spawn.
- **Rulings file** (`docs/jobs/<issue-slug>-rulings.md`) - orchestrator-owned,
  append-only post-freeze intent: PHASE-0 rulings, boundary amendments,
  respawn answers. Part of the judge's intent context.
- **Verdict comment** - the judgment record posted on the issue: per-check
  PASS/FAIL/INVALID, checks integrity, diff-vs-intent, and the slice call.
- **Canary** - the preflight spawn that proves a builder backend actually has
  working tools before the decomposition records it.
- **Dispatch rules** - optional `when -> cli/model:effort - why` lines in
  `.architect/config` that route task classes to builder tiers; absent file =
  tier-down default.
- **Post-flight** - the orchestrator's mechanical checks on a completed job
  (boundaries, check-file integrity, raw-only report, status-line form) before
  integration. Distinct from judgment.
- **Codify** - the compound step: nontrivial diagnoses become
  `docs/solutions/<slug>.md`, read back at grounding so each run makes the next
  one easier.
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
