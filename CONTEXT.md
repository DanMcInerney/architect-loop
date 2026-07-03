# CONTEXT — ubiquitous language for architect-loop

Glossary only. No implementation details, no spec content.

## Roles

- **Orchestrator** (colloquially **the brain**) — the single interactive
  session the human opens (any harness, any surface). Grounds, runs intake,
  decomposes, freezes, dispatches, arbitrates, diagnoses, integrates. Never
  writes implementation code, never reads large diffs, never judges gates.
- **Brain** — the model tier the orchestrator runs on. Also the judge's
  tier: "the brain" names a capability level, not one process.
- **Builder** (colloquially **brawn**) — a cold-context worker agent that
  implements exactly one issue in an isolated worktree. Cannot commit. The
  brawn tier is typically cheaper than the brain tier and never changes
  because a lane failed.
- **Judge** — a cold-context, read-only agent at brain tier that runs an
  issue's frozen gates and returns verdicts with raw evidence. "The brain
  with fresh eyes": same capability as the orchestrator, none of its
  conversation. Not a config key.
- **Monitor** — a cheap detection-only background subagent that sweeps
  in-flight lanes (~10 min) and exits with evidence on anomaly. Never
  kills, never nudges, never judges; its completion is the alert.
- **Grill** — a cold adversarial reviewer of the decomposition before the
  freeze: attacks gate commands, issue bodies, and repo reality.
- **Scout** — a lane-shaped investigator: reads, researches, reports; may
  not modify code.

## Units of work

- **Issue** — one vertical-slice unit of work, one GitHub issue, one
  builder lane. Body carries what-to-build, acceptance criteria, boundaries
  (disjoint file sets), and interface handoff blocks.
- **Epic** — the run's parent issue: dashboard, digest, and preflight
  record. Sub-issues hang off it with native blocked-by edges.
- **DAG / frontier** — the dependency graph of issues; the schedulable set
  is always the unblocked frontier, dispatched up to five lanes at once.
- **Wave** — one frontier dispatch: its lanes plus one monitor.
- **Factory run** — everything between spec-gate approval and the closing
  PR; runs unattended on the factory branch (`factory/<run>`).

## Control & memory

- **Tracker** — GitHub issues are the coordination state: claims are
  assignments, progress and verdicts are comments, the epic carries the
  digest. "Not in the tracker = didn't happen."
- **Spec gate** — the one human step: review one spec document, edit or
  veto its recorded assumptions, approve. Approval authorizes the DAG.
- **Gate** — a frozen, committed, exact acceptance check
  (`docs/gates/<issue-slug>.md`). Read-only for everyone once frozen.
- **Freeze commit** — the commit that locks a run's gates; it is pushed
  before any dispatch, and worktrees are verified against it after spawn.
- **Rulings file** (`docs/lanes/<issue-slug>-rulings.md`) — orchestrator-
  owned, append-only post-freeze intent: PHASE-0 rulings, boundary
  amendments, respawn answers. Part of the judge's intent context.
- **Verdict comment** — the judgment record posted on the issue: per-gate
  PASS/FAIL/INVALID, gates integrity, diff-vs-intent, and the slice call.
- **Canary** — the preflight spawn that proves a brawn backend actually has
  working tools before the decomposition records it.
- **Dispatch rules** — optional `when → cli/model:effort — why` lines in
  `.architect/config` that route task classes to brawn tiers; absent file =
  tier-down default.
- **Post-flight** — the orchestrator's mechanical checks on a completed lane
  (boundaries, gates-file integrity, raw-only report, status-line form)
  before integration. Distinct from judgment.
- **Codify** — the compound step: nontrivial diagnoses become
  `docs/solutions/<slug>.md`, read back at grounding so each run makes the
  next one easier.
- **docs/STOP** — kill file; its presence halts the factory before the next
  dispatch.

## Retired terms (historical; appear in pre-v5 docs and git history)

- **Handoff / `docs/HANDOFF.md`** — v3/v4 repo-memory diary; retired in v5.
  The tracker and git are the memory.
- **Judgment ledger** — the handoff section that recorded verdicts; replaced
  by verdict comments on issues.
- **Heartbeat** — the v4 orchestrator stall-check; replaced by the monitor.
- **Slice / block** — v4's unit and iteration names; v5 says issue and
  factory-loop event.
- **Sentinel / `LOOP:` line** — v3 driver-control protocol; deleted in v4.
- **Driver** — the v3 external loop script (`bin/architect-loop.*`);
  deleted in v4. The loop is the orchestrator conversation itself.
- **PRD** — renamed to **spec** (2026-07-02). "PRD" is retired; "spec" is
  the current term everywhere the loop refers to a specification document.
