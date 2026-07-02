# Gates — slice `v4-docs` (milestone docs lane)

Frozen BEFORE dispatch (post-grill; 8 draft defects fixed — grill row in
`docs/HANDOFF.md` session log). Read-only after the freeze commit; any later
edit is an automatic slice FAIL.

Purpose: consume the Docs debt table in `docs/HANDOFF.md` (P7 convention,
first use) before PR #9 merges — product docs catch up with what shipped.
Spec reference: the Docs debt row for `loop-hardening` in `docs/HANDOFF.md`
plus the "Human APPROVED P1–P7" Decisions-log row (P7's rationale lives
there, NOT in the research doc). Per P7, product docs are edited ONLY by
this dedicated lane.

Standing exemption: orchestrator commits whose changed paths are a subset
of {`docs/HANDOFF.md`, `docs/gates/**`} are exempt from MG4's allowlist;
all other commits in the window are builder-lane commits and are bound by it.

## Fix contract

- **README.md:** in the `## Use (one interactive session)` section, briefly
  document (a) the pre-freeze spec grill (a cold subagent falsifies the
  draft gates before they freeze) and (b) the docs-debt flow (each shipped
  slice logs a one-line docs-debt pointer; one dedicated docs lane consumes
  the list at the PR boundary). Keep the README's voice; ~10–20 lines
  total. Inline non-anchored relative links are validator-checked; any
  anchored links are judge-verified by hand.
- **DESIGN.md:** append a new evidence section (following §9's entry style,
  which uses full markdown links) covering P1–P7. P1–P6 entries cite
  `docs/research/loop-improvements.md` — note it holds citation SHORTHAND
  (arXiv IDs, bare domains), so expand to full URLs per §9 style where the
  research doc's Key-citations list identifies them. P7's entry cites the
  "Human APPROVED P1–P7" Decisions-log row in `docs/HANDOFF.md` (the
  research doc does not contain P7). Where a proposal number and the
  as-shipped number differ, cite the research doc for the PROPOSAL and
  `docs/HANDOFF.md` for the AS-SHIPPED value and say so explicitly (P2:
  proposal cited "2 spec defects", as-shipped first-use result is 5
  pre-freeze catches; P5: proposal was ~150–200 imperative instructions,
  shipped guard is 800 non-blank lines). Do not rewrite existing sections.
- **HISTORY IMMUTABLE:** no other file changes. Clearing the Docs debt
  table row is the orchestrator's post-merge bookkeeping, not this lane's.

## Declared timeout ceilings

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| git commands | 120s |
| anything else | 600s (default) |

## Gates

**MG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND PowerShell on the integration branch.

**MG2 — README covers both items, in place.** `grep -ci "grill" README.md`
≥ 1 AND `grep -ciE "docs.?debt" README.md` ≥ 1 (both are 0 at freeze —
falsifiable), AND the judge verifies both mechanisms are described inside
the `## Use (one interactive session)` section in the README's voice.

**MG3 — DESIGN.md evidence complete.** Judge reads the new section: one
entry per P1–P7; P1–P6 cite `docs/research/loop-improvements.md` (URLs
expanded per §9 style); P7 cites the HANDOFF Decisions-log rationale row;
P2's entry records the as-shipped first-use grill result (5 catches) and
P5's the as-shipped 800-non-blank-line guard, each distinguished from the
research-doc proposal figures.

**MG4 — Bounded lane diff (allowlist, per-commit).** For every commit in
`<freeze>..HEAD` (`git log --format=%H --name-only <freeze>..HEAD`): either
its changed paths are a subset of {`docs/HANDOFF.md`, `docs/gates/**`}
(standing exemption, orchestrator-only), or its changed paths are a subset
of {`README.md`, `DESIGN.md`, `docs/lanes/v4-docs-01.md`} (builder lane).
Across all lane commits, exactly those three files change and
`docs/lanes/v4-docs-01.md` is new.
