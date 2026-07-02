# Gates — slice `loop-hardening` (P1–P7)

Frozen BEFORE dispatch (post-grill draft; grill report applied — see the
2026-07-02 grill row in `docs/HANDOFF.md` session log). Read-only after the
freeze commit; any later edit is an automatic slice FAIL.

Purpose: implement proposals P1–P6 from `docs/research/loop-improvements.md`
§"Proposed changes" (evidence anchors live there) **plus P7 (docs debt),
whose design is recorded in the 2026-07-02 "Human APPROVED P1–P7" row of
`docs/HANDOFF.md`'s Decisions log and restated in the P7 fix contract
below (self-contained).** Human approval + brawn=claude/sonnet /
Fable-for-review rulings: same Decisions-log row.

Standing exemption: orchestrator commits touching ONLY `docs/HANDOFF.md`
and/or `docs/gates/` freeze files are exempt from bounded-diff enumerations.

## Fix contract

- **P1 (no failure-masking code):** the `## Builder block template` in
  `skills/architect/dispatch.md` AND the Operating-rules list in
  `.claude/agents/architect-builder.md` gain a ban: no silent fallbacks or
  success-shaped defaults (never swallow an error to make output look
  right); no unrequested backwards-compatibility shims or dead
  compatibility code; fail loudly with context. Exception clause:
  fallbacks/compat ONLY when the spec explicitly requests them. Concise —
  a few lines each, matching voice.
- **P2 (pre-freeze spec grill):** `skills/architect/SKILL.md` gains a grill
  step between `### 5. Spec` and the freeze commit (inside or adjacent to
  `### 6. Freeze`): ONE cold read-only subagent receives the DRAFT gate
  file path and must try to falsify it — execute each gate command against
  the current tree, verify referenced paths/SHAs/pointers resolve, attack
  acceptance criteria for non-falsifiability and for patterns colliding
  with repo realities (e.g. repo-name grep collisions), and flag
  assumptions not evidenced in the repo. Default ON for the first slice in
  a repo and for high-stakes slices; skippable for trivial slices
  (scale-to-task). The orchestrator fixes the draft, then freezes.
  `skills/architect/dispatch.md` gains a FIXED grill delegation template
  modeled on the `## C5 judge delegation template` (marker-delimited,
  pointer-only: draft gate path + branch + defect-report format; text
  forbids adding slice-specific prose).
- **P3 (slice-size discipline):** SKILL.md's `### 5. Spec` step states:
  target judged diffs ≤ ~400 changed lines; a spec whose diff will clearly
  exceed it should be split into smaller slices.
- **P4 (repeat-action stall signal):** dispatch.md's `## Stall detection
  and rescue` section adds: a lane repeatedly issuing the same
  command/query with identical arguments is stalled even if its
  event/report file is still growing.
- **P5 (size guard):** `tests/validate_skills.py` gains a guard that FAILS
  when the combined NON-BLANK line count of `skills/architect/SKILL.md` +
  `loop.md` + `dispatch.md` exceeds **800**, with a comment stating the
  basis (instruction-budget overflow evidence, docs/research/
  loop-improvements.md P5; measured 510 at freeze time). The constant 800
  and the non-blank basis are binding for this slice.
- **P6 (tier-up over retry):** dispatch.md, in `## Model resolution and
  dispatch rules` or adjacent to the `## Model alias table`, adds one line:
  when a lane fails once, prefer raising its model tier over re-running at
  the same tier.
- **P7 (docs debt — design self-contained here):** two doc classes, two
  cadences. Memory docs (handoff/gates/lanes) update continuously per
  block, orchestrator-owned — unchanged. Product docs (README, DESIGN.md,
  guides) are NEVER edited by build lanes or by the orchestrator; instead:
  (a) SKILL.md `### 2. Judge` — every CONTINUE verdict appends ONE
  docs-debt pointer line to the handoff (what shipped → what product-doc
  update it needs); (b) SKILL.md `### 8. Next block` (or `### 2. Judge`) —
  before merging a milestone to origin (the PR boundary), one dedicated
  docs LANE consumes the docs-debt list; (c) `skills/architect/loop.md`
  `## Judgment ledger` gains the matching docs-debt line;
  (d) `skills/architect/HANDOFF.template.md` gains a "Docs debt" section
  (one pointer line per shipped slice, consumed by the milestone docs lane).

## Declared timeout ceilings

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| git commands | 120s |
| anything else | 600s (default) |

## Gates

**LG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND PowerShell on the integration branch.

**LG2 — P1 text present in both places.** Judge reads the
`## Builder block template` and `.claude/agents/architect-builder.md`
against the P1 fix contract (ban + exception clause in both).

**LG3 — P2 grill step + fixed template.** Judge reads SKILL.md (grill step
between spec and freeze with the default-on/skip conditions) and
dispatch.md (marker-delimited pointer-only grill template present; text
forbids slice-specific prose).

**LG4 — P3 line present in SKILL.md's `### 5. Spec`.** Judge reads.

**LG5 — P4 line present in dispatch.md's `## Stall detection and rescue`.**
Judge reads.

**LG6 — P5 guard live and pinned.** `tests/validate_skills.py` contains the
guard with the constant 800 and a non-blank counting basis stated in its
comment (read source), AND the suite passes on the tree (LG1) — i.e. the
post-change skill text is under the ceiling.

**LG7 — P6 line present in dispatch.md.** Judge reads.

**LG8 — P7 in all three skill files.** Judge reads SKILL.md (docs-debt
append on CONTINUE + milestone docs lane + product-docs-never-by-build-
lanes/orchestrator), loop.md (`## Judgment ledger` docs-debt line), and
HANDOFF.template.md ("Docs debt" section).

**LG9 — Bounded lane diff.** The builder lane commit changes AT MINIMUM:
`skills/architect/SKILL.md`, `skills/architect/dispatch.md`,
`skills/architect/HANDOFF.template.md`,
`.claude/agents/architect-builder.md`, `tests/validate_skills.py`,
`docs/lanes/loop-hardening-01.md` (new); PLUS optionally
`skills/architect/loop.md`; and NOTHING else.
`git diff <freeze>..HEAD -- docs/gates/ docs/spec/ docs/adr/ docs/research/
CONTEXT.md README.md DESIGN.md .claude/agents/architect-judge.md
.claude/settings.json install.sh install.ps1` is EMPTY apart from
standing-exemption commits.
