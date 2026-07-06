---
name: to-spec
description: >
  Spec-writing stage skill for the architect factory: synthesizes the run's
  conversation, repo evidence, and research findings into `docs/spec/<run>.md`
  after grounding. Invoked directly by the orchestrator (/architect) during
  intake, before decomposition into issues.
---

<!-- Adapted from mattpocock/skills (MIT). -->

# To Spec

Synthesize the spec from what grounding, intake, and research evidence
already surfaced; do not interview. Anything genuinely unanswered goes
through step 4.

## Process

1. Read the run's `docs/runs/<run>/map.md` and the codebase-design
   vocabulary before writing a line. Reuse its module, interface, seam,
   adapter, depth, and locality terms exactly; never substitute component,
   service, boundary, or API for module or interface.
2. Name the seam(s) this run will exercise before drafting any section.
   Existing seams are preferred to new ones, at the highest point possible;
   the ideal number is one. Record them under `## Implementation decisions`.
3. Do not include specific file paths or code snippets in the spec body —
   they may end up being outdated very quickly. Exception: if a prototype
   produced a snippet that encodes a decision more precisely than prose can
   (state machine, schema, type shape), inline it within the relevant
   decision and note briefly that it came from a prototype. Trim to the
   decision-rich parts.
4. Send every open question through the timed-ruling protocol
   (`skills/architect/SKILL.md` `### 2. Spec Approval`) instead of asking
   directly, and record the outcome as an `## Assumptions` entry — do not
   restate the protocol itself.
5. Shape the spec on the template below; commit it at `docs/spec/<run>.md`.
   Then create or update the tracking issue — or its markdown-mode
   equivalent, `skills/architect/tracker.md` `## Command mapping` — with the
   spec pointer, an assumptions digest, and the three approve-by-comment
   forms: `APPROVE`, `APPROVE with edits: <text>`, `REJECT <reason>`.

## Template

Write the sections below in this order; the names are load-bearing for
approval and decomposition, so keep them exact.

- `## Goal` — what the run adds and why, from the reader's side.
- `## Target flow` (optional) — a short numbered sequence, only when the run
  reorders or replaces a multi-step process; omit for additive or
  single-surface runs.
- `## Non-goals` — what the run deliberately leaves unchanged.
- `## Assumptions` — every timed-ruling default this run applied, one line
  each, dated.
- `## Implementation decisions` — modules, interfaces, and the seam(s) from
  step 2, described, never pathed; the one place a prototype snippet may
  appear, per step 3.
- `## Validation strategy` — how the run's own checks and the closing
  review confirm the seam(s) hold; name the check-runner and intent judge,
  never new grading machinery.
- `## Domain language` — new or changed vocabulary this run introduces,
  defined once.
- `## Open human decisions` — anything unresolved once the timed-ruling
  protocol's timer expires; empty at freeze.
- `## Verified facts` — every claim sourced outside this conversation:
  source, date fetched, fact supported.
- `## Preflight evidence` — tool, auth, and repo-state evidence gathered
  before decomposition.
- `## Approval record` — the exact authorization form, quoted; the three
  forms are defined in `skills/architect/SKILL.md` `### 2. Spec Approval`.
