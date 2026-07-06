---
name: to-spec
description: >
  Spec-writing stage skill for the architect factory: synthesizes the run's
  conversation, repo evidence, and research findings into `docs/spec/<run>.md`
  after grounding. Invoked directly by the orchestrator (/architect) during
  intake, before decomposition into issues.
---

# To Spec

<!-- Shape adapted from mattpocock/skills (MIT), skills/engineering/to-prd/SKILL.md -->

Synthesize the spec from what grounding, intake, and research evidence
already surfaced; do not interview. Anything genuinely unanswered goes
through step 4.

## Process

1. Read the run's `docs/runs/<run>/map.md` and the codebase-design
   vocabulary before writing a line. Reuse its module, interface, seam,
   adapter, depth, and locality terms exactly; never substitute component,
   service, boundary, or API for module or interface.
2. Name the seam(s) this run will exercise before drafting any section.
   Prefer an existing seam, as high as the codebase offers; one new seam is
   the most a run should need. Record the seam(s) under
   `## Implementation decisions`.
3. Keep file paths and code snippets out of the spec body — file layout
   moves, decisions should not. One carve-out: when prototyping settled
   something prose would leave ambiguous (a config grammar, a frontmatter
   key set, a typed-exit table), inline just the lines that pin the choice
   down and mark their prototype origin.
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
