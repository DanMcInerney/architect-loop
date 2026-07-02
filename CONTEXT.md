# CONTEXT — ubiquitous language for architect-loop

Glossary only. No implementation details, no spec content.

## Roles

- **Orchestrator** — the single interactive session the human opens (any
  harness, any surface). Grounds, arbitrates, specs, freezes, dispatches,
  integrates. Never writes implementation code, never judges gates.
- **Brain** — the model tier the orchestrator runs on. Also the judge's tier:
  "the brain" names a capability level, not one process.
- **Builder** (colloquially **brawn**) — a cold-context worker agent that
  implements exactly one lane. Cannot commit. The brawn tier is typically
  cheaper than the brain tier.
- **Judge** — a cold-context, read-only agent at brain tier that runs a
  slice's frozen gates and returns verdicts with raw evidence. "The brain
  with fresh eyes": same capability as the orchestrator, none of its
  conversation. Not a config key.
- **Scout** — a lane-shaped investigator: reads, researches, reports;
  may not modify code.

## Units of work

- **Slice** — one PR-sized unit of specced work; the loop's iteration
  granularity.
- **Lane** — one builder's share of a slice (1–4 per slice, provably
  disjoint file sets). A lane is either **ship** (code change, full gates)
  or **scout** (report only).
- **Block** — one orchestrator pass over one slice: ground → arbitrate →
  judge → integrate → spec → dispatch. One block per slice; re-grounding
  happens at every block boundary.

## Control & memory

- **Handoff** (`docs/HANDOFF.md`) — the repo's working memory. "Not in the
  handoff = didn't happen."
- **Gate** — a frozen, committed, exact acceptance check
  (`docs/gates/<slice>.md`). Read-only for everyone once frozen.
- **Freeze commit** — the commit that locks a slice's gates; dispatch may
  only happen after it.
- **Judgment ledger** — the handoff section recording each slice's verdicts;
  replaces the retired sentinel protocol as the loop's state record.
- **Heartbeat** — a periodic orchestrator check-in on in-flight lanes,
  used as the stall-detection fallback when no completion signal arrives.
- **Dispatch rules** — optional `when → cli/model:effort — why` lines in
  `.architect/config` that route task classes to brawn tiers; absent file =
  tier-down default.
- **Post-flight** — the orchestrator's mechanical checks on a completed lane
  (boundaries, gates-file integrity, raw-only report) before integration.
  Distinct from judgment.
- **docs/STOP** — kill file; its presence halts the loop before the next
  dispatch.

## Retired terms (historical; appear in pre-v4 docs)

- **Sentinel / `LOOP:` line** — v3 driver-control protocol; deleted in v4.
- **Driver** — the v3 external loop script (`bin/architect-loop.*`);
  deleted in v4. The loop is the orchestrator conversation itself.
