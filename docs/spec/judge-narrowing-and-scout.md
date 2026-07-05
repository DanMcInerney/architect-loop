# Spec: judge-narrowing-and-scout

Reshape per-slice verification and pre-spec grounding per the 2026-07-05
judge-value audit and its same-day adversarial review: mechanical grading
moves into the deterministic check-runner, the cold judge narrows to
intent-only, and a pre-spec code scout produces a committed map that grounds
the spec, the decomposition skeletons, and every builder.

## Evidence digest (why)

- **Transcription waste is measured, not hypothetical.** harden-01's judge
  FAIL cited `exit: 1` that was already verbatim in the committed checkrun
  evidence file; a frontier judge run was spent reading an exit code. The
  s1/s2 multi-run PASS verdicts are mostly re-transcription of evidence-file
  outputs the runner had already recorded.
- **The judge stays per-slice; #17 is the proof.** v5 issue #17
  (v5-handoff-retire): gates HR1–HR5 ALL PASS, integrity PASS, SLICE FAIL on
  diff-vs-intent only — the builder added a validator exception with the
  filename constructed from fragments to evade the frozen HR3 literal grep,
  masking README.md:170's dead link. A low-stakes-looking slice, all-green
  deterministic checks, caught only by intent review. Stakes-gating and
  random audits are rejected (builders are fresh contexts and cannot
  condition on judge probability; "deterrence" was anthropomorphized).
- **The runner cannot grade today by design.** The RUN grammar treats
  everything after the closing backtick as judge-facing prose the runner
  ignores; absence checks PASS on exit 1 (e.g. multi-run s1 line 23), so
  exit-code-only grading is wrong without machine-readable expectations.
- **Judgment budget goes to intent, not re-grading.** TRACE
  (`.architect/research/02-llm-judge-rubric.md`): code-quality LLM judges
  align with humans only 6–18% above chance; Anthropic evals guidance
  separates deterministic correctness from LLM review.
- **Amortized exploration has shipped precedent.** The A1 research-loop
  pattern (heavy reading in lanes, capped ~2,500-token returns with anchors)
  and the existing `scout` job shape; today every parallel builder re-explores
  the codebase from scratch.

## Goal

- **G1 — Graded RUN checks with typed runner verdicts.** Extend the RUN
  grammar with machine-readable expectations immediately after the command
  span: `- RUN: `<cmd>` -> exit:<n>` with optional `match:"<substring>"`
  (fixed substring, grep -F semantics) against stdout — amended from regex by
  the pre-freeze ruling on #98: .NET-regex-vs-POSIX-ERE divergence between
  the ps1/sh runners would make graded verdicts executor-dependent. Text after the expectation stays judge-facing prose. The
  check-runner grades each RUN item, records per-item PASS/FAIL plus a
  summary in the evidence file, and exits typed: 0 = all RUN items PASS,
  2 = any FAIL, 5 = `CHECKRUN: ERROR` unchanged. The orchestrator rules on
  the typed exit; exit 2 goes straight to the failure ladder with no judge
  dispatch (the harden-01 path). The grill clause extends: every mechanical
  check MUST carry an expectation; a RUN item without one is a check defect.
  Fixtures under `tests/fixtures/checkrun/` gain graded cases including an
  absence check (`exit:1`) and a `match:` case, both executors.
- **G2 — Intent-only judge.** Both judge templates (C5 and codex) shrink to:
  read the frozen check file, spec, job report, rulings file, checkrun
  evidence summary, and the diff; return Checks-integrity, Diff-vs-intent,
  and the Slice verdict with one decisive reason — no per-RUN re-grading or
  transcription blocks. Keep exactly one spot-check re-run of a graded RUN
  item (mismatch = automatic INVALID) as the runner-defect honesty guard —
  this class caught the first-live-use quoting defect. Tree audit and
  INVALID-on-stale-evidence rules unchanged. `architect-judge.md` duties
  updated to match. Judges run at the resolved builders model (already live
  in the working tree, 2026-07-05: SKILL.md Hard Rule 3 + Ground + loop step,
  dispatch.md per-harness Judge row; this spec is the durable record).
- **G3 — Pre-spec code scout and committed map.** At intake, in parallel with
  the intake question batch and its 5-minute timer, dispatch one read-only
  scout job (builders model, `scout` shape): return ≤~2,500 tokens mapping
  key modules/files, load-bearing types and function signatures, conventions
  and patterns, testing seams, and gotchas — every entry with file:line
  anchors, `NOT FOUND` recorded honestly, no recommendations. The
  orchestrator commits it as `docs/runs/<run>/map.md`. The spec and
  decomposition cite the map; every issue body carries the map pointer so
  builders navigate without re-exploring; the grill spot-checks a sample of
  map anchors against the tree (extends its existing pointer-resolution
  duty). Builders' FIRST-ACTION verification remains the last defense against
  a stale map.
- **G4 — Change-skeletons drive decomposition.** The spec and each issue
  carry a compact change-skeleton grounded in the map: ≤~30 lines per issue
  of files, signatures, data flow, and invariants — structure only, no
  bodies. The skeleton is a contract, not a line-by-line mandate; PHASE 0
  disagreement governs conflicts with reality. Decomposition computes the
  parallel frontier from skeleton file-ownership so disjointness is proved
  before dispatch, not discovered as a merge conflict.
- **G5 — Human-gated closing review.** After the last build issue closes and
  before the docs-finish job and closing PR, the orchestrator asks through
  the timed-ruling protocol: one comprehensive closing review, recommended
  default YES; 5 minutes of silence applies the default. On yes, dispatch one
  fresh subagent at the resolved ORCHESTRATOR model at medium effort, in a
  worktree cut from the factory branch head, with the spec path, the scout
  map path, the full run diff, and rulings/solutions pointers. Its task:
  review the shipped work for correctness, simplification, DRY, and dead
  code, starting from the spec, then the map, then the diff; make the final
  changes directly; `docs/checks/` stays read-only (an edit there fails the
  pass); every graded RUN item across the run must stay green; finish by
  re-running the full run check set plus the named test suites and reporting
  raw evidence with a diffstat. The orchestrator merges through postflight
  and records the review verdict and diffstat on the tracking issue. If the
  closing checkrun goes red and the reviewer cannot restore green, the review
  worktree is discarded whole — the run merges without the review changes,
  recorded on the digest; red review changes are never merged. On NO, record
  the ruling and skip. The closing review is additive to per-slice judging,
  and it supersedes the previously deferred duplication-triggered
  consolidation lane.

## Non-goals

- No stakes-gating of the judge and no random audit sampling (rejected on
  #17 and the fresh-context argument above).
- No standing duplication-detector consolidation lane: G5's human-gated
  closing review supersedes it.
- No small-task carve-outs (tiny-tree scout skip, per-slice skeleton
  exemptions): a future `/architect-fast` skill owns the small-task lane;
  every `/architect` run pays scout + skeletons.
- docs-finish no-judge exception unchanged; grill, freeze, preflight,
  postflight, failure ladder, and Hard Rules unchanged except where named.
- Fast-mode pins stay builder-only; the judge change is model, not speed.

## Assumptions (approve or veto at approval)

- **A1 (amended by #98 ruling):** Expectation grammar is exactly
  `-> exit:<n>` with optional `match:"<substring>"` — fixed substring over
  stdout, case-sensitive, never regex. Regex upgrade deferred until a real
  check needs it.
- **A2:** A builders-model judge may be same-family as the builder (codex
  judging codex): the #17 catch was a codex judge on codex work, and
  cross-family review remains the recorded high-stakes escape hatch.
- **A3:** Scout return cap ~2,500 tokens (A1 research-loop precedent); map
  path `docs/runs/<run>/map.md`.
- **A4:** The five-file guard stays at 1100 non-blank lines; G2's template
  shrink is expected to offset G3/G4 additions. If it cannot, raising the cap
  follows the ~6% headroom convention and is a tracked approval item, never a
  silent bump.
- **A5:** The 2026-07-05 working-tree edits (builders-model judge text;
  codex Fast builder default in dispatch.md) ride into the run's factory
  branch as pre-approved context and are not re-implemented by builders.
- **A6:** The closing review runs before the docs-finish job so the docs job
  documents the final code; its postflight touch-set is the union of the
  run's per-issue touch-sets, with any reviewer addition beyond that union
  recorded on the tracking issue rather than auto-failed.
- **A7:** "Nobody grades their own work" is satisfied for the closing review
  by the human gate plus the deterministic closing checkrun; no cold judge
  re-reviews the reviewer. Veto → add a cold intent judge on the review diff.

## Validation strategy

- G1: extended checkrun fixtures pass under both executors with typed exits
  0/2 asserted (absence-check fixture must PASS via `exit:1`); grill clause
  and RUN grammar text updated in `dispatch.md` — frozen check greps;
  `tests/validate_skills.py` suite stays green.
- G2: both judge templates contain no per-check verdict block (grep absence
  of the `Per check:` section) and retain integrity, intent, spot-check, and
  INVALID rules — frozen check greps against `dispatch.md` and
  `.claude/agents/architect-judge.md`.
- G3: SKILL.md intake names the scout dispatch parallel to the question
  batch; map path convention and grill anchor spot-check present — greps.
- G4: decomposition section requires the skeleton block and
  ownership-derived parallel frontier — greps.
- G5: SKILL.md Finish opens with the timed-ruling closing-review question
  (default YES), names the orchestrator-model-at-medium pin, the
  spec→map→diff reading order, the docs/checks/ read-only rule, the
  green-or-discard rail, and ordering before the docs job — greps.
- End-to-end: the first factory run after merge exercises graded checkrun →
  typed exit → intent-only judge live and records the evidence in DESIGN.md.

## Domain language

- **Graded RUN** — a RUN item with a machine-readable expectation the runner
  scores. **Intent judge** — the narrowed judge: integrity + diff-vs-intent
  + one spot-check, no re-grading. **Scout map** — the committed
  ≤~2,500-token code map with file:line anchors. **Change-skeleton** — the
  per-issue structural pseudocode contract that proves decomposition
  disjointness. **Closing review** — the human-gated, orchestrator-model
  medium-effort review-and-fix pass at the PR boundary, green-or-discarded.

## Approval record

In-session approval, 2026-07-05: after directing this spec's design
in-session (judge audit, adversarial review, G1–G5 scope, no small-task
carve-outs, closing-review step), the repo owner invoked, verbatim:
`/architect build it`. Tracking issue #98 carries the assumptions digest and
after-the-fact veto instructions.

## Open questions (carried, not blocking)

- No documented signal confirms Fast mode activates under `codex exec`
  (`/fast` is TUI-documented); the first run records whatever evidence the
  session files expose.
- Should judges also carry the Fast pins now that they run the builders
  model? Human call; default no.
- `match:` semantics: settled by the #98 ruling — fixed substring found
  anywhere in captured stdout; no anchoring, no regex.
