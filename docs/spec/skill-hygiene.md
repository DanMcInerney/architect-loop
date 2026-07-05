# Spec: skill-hygiene

Bring `/architect` and `/architect-research` in line with the verified subset
of the r6 skill-design research (git SHA `0b490f6`, history-only per human
ruling), corrected by the adversarial review recorded below. Small,
evidence-first slice: description rewrite, TOCs, prescriptiveness audit,
guard updates, trigger-eval fixture.

## Adversarial review of the r6 report (corrections digest)

The report is history-only; this digest is its durable correction record.
Every check below was made by direct fetch or direct file read this session
(2026-07-04).

**Survived re-verification (build on these):**

- F1 official rule set: 500-line SKILL.md ceiling, TOC required for reference
  files >100 lines, one-level-deep references, 1024-char third-person
  descriptions, degrees-of-freedom frame — all confirmed verbatim at
  platform.claude.com best-practices. Claude Code specifics confirmed verbatim
  at code.claude.com/docs/en/skills: listing budget = 1% of context window
  (least-invoked descriptions dropped first), 1,536-char cap per
  `description + when_to_use` entry ("put the key use case first"),
  compaction reattaches first 5,000 tokens per invoked skill under a
  25,000-token combined budget (most-recent first; older skills dropped
  entirely), `when_to_use` exists, `disable-model-invocation` removes the
  description from context.
- F5 Fable guidance: the prescriptiveness quote is verbatim on the Fable 5
  prompting page, as are the `reasoning_extraction` refusal warning
  ("Don't instruct Claude to reproduce its reasoning in the response") and
  "Separate, fresh-context verifier subagents tend to outperform
  self-critique."
- F2 SkillsBench: arXiv 2602.12670 exists; submitted 2026-02-13, v4
  2026-06-14 (reconciles the ID/date question). Abstract confirms +16.6pp
  (33.9%→50.5%) and "Focused Skills with at most three modules outperform
  larger or exhaustive bundles."
- Local claims: `/architect-research`'s description does summarize the
  workflow; `/architect`'s is trigger-only; `dispatch.md` has no TOC.

**Defects found (the spec incorporates the fixes):**

1. **Stale counts.** Actual today: SKILL.md 257 lines (213 non-blank),
   dispatch.md 684 (546), loop.md 130 (108); guard total **867/900**, not
   849/900 — 33 lines of headroom, and the report's own TOC recommendation
   consumes guard-counted lines. The report never notes this tension between
   its items 2 and 4.
2. **Live contradiction the audit missed:** `DESIGN.md:572` says "800-non-
   blank-line size guard" while `tests/validate_skills.py:395` enforces 900.
   Exactly the F5 contradiction category. Must be fixed.
3. **Under-scoped TOC recommendation.** The report audited only the architect
   trio. `skills/architect-research/tactics.md` is 193 lines — a reference
   file >100 lines needing a TOC under the same official rule. `tracker.md`
   (79) and `research.md` (89) are under 100 and exempt.
4. **Guard-scope loophole.** The 900 guard counts only
   SKILL.md+loop.md+dispatch.md. tracker.md, research.md, and the entire
   architect-research skill (183+193 lines) are uncounted.
5. **Unverified attribution.** The claim "Anthropic's Opus 4.5+/Fable
   guidance says `CRITICAL: You MUST use…` now overtriggers — write plain
   'Use when…'" appears on neither the Fable page nor the Claude Code skills
   page; a secondary source reports the opposite emphasis (undertriggering is
   the more common failure; descriptions should be "slightly pushy").
   Downgraded to UNVERIFIED; immaterial here (neither description uses such
   wording), but no requirement in this spec may depend on it.
6. **Weak inference stated strongly.** "Standard beats compact (+21.5 vs
   +19.0pp) so do NOT compress" rests on a 2.5pp delta the paper itself
   caveats as length-confounded, and the granular size-ablation numbers are
   not in the abstract. The *direction* (don't chase 200 lines; avoid
   exhaustive) stands on the confirmed abstract; the specific delta is weak
   evidence and is not load-bearing here.
7. **Deployment blind spot.** "We have 2 skills" is repo-scoped. Real install
   environments run this alongside dozens of other skills competing for the
   1%-of-context listing budget with least-invoked-dropped-first policy. The
   description economy matters more than the report allowed; this strengthens
   the rewrite requirement (front-load the key use case).
8. Trivia: F4 issue dates "2025-12..2026-05" vs citation line "2026-01..05";
   report line counts drifted (D14 fix landed after its audit).

## Goal

Both skills conform to the verified official envelope and the corrected
findings:

- **G1 — Trigger-only description for `/architect-research`.** Rewrite the
  `description:` frontmatter to state what the skill does and when to trigger
  it, key use case first, no workflow summary (drop "a cheap scout
  researcher maps the topic, the orchestrator designs… verifies…
  synthesizes"). Keep the existing trigger phrases ("research X", "state of
  the art", "deep research", brainstorming) and the "/architect handles
  slice-level fact checks inline" boundary line. Target well under 1,024
  chars; front-load per the 1,536-char listing cap. `/architect`'s
  description is already conformant — do not change it.
- **G2 — TOCs for all reference files >100 lines:** `dispatch.md` (684),
  `loop.md` (130), `tactics.md` (193). Short contents block at top listing
  the `##` sections, matching each file's existing section names exactly
  (SKILL.md section-pointers must keep resolving). `tracker.md` and
  `research.md` are exempt (<100 lines).
- **G3 — One-time Fable-era prescriptiveness audit** across both skills'
  files. Criterion per line: does it change behavior vs. the model's default
  (keep only if yes), and is it a contract/boundary/fragile-op rail (keep) or
  process prescription (delete candidate)? Specific scans: echo-your-
  reasoning phrasing (verified `reasoning_extraction` refusal risk);
  contradictions between SKILL.md, dispatch.md, loop.md, tracker.md,
  research.md, DESIGN.md — including the known 800-vs-900 guard
  contradiction (fix DESIGN.md to match the enforced 900). Hard Rules 1–9
  semantic content is untouchable (low-freedom rails under the official
  degrees-of-freedom frame); wording-only tightening allowed. Deletions land
  as one reviewable diff with a per-deletion one-line justification in the
  job report.
- **G4 — Guard updates in `tests/validate_skills.py`:** (a) keep a combined
  non-blank guard but extend counting to all five architect files
  (SKILL.md, dispatch.md, loop.md, tracker.md, research.md), cap **1100**
  (current 1002 + TOC additions + ~6% headroom, same headroom convention as
  the 849→900 precedent); (b) new guard: architect-research SKILL.md +
  tactics.md combined non-blank ≤ **500** (current 322); (c) new guard: each
  SKILL.md body < **5,000 tokens** (word-count proxy acceptable; record the
  proxy formula in the test) so bodies reattach whole after compaction;
  (d) update the guard's recorded rationale: the evidence cliff is
  exhaustive/comprehensive content and skill count, not line 200; compaction
  reattach economics are the binding constraint.
- **G5 — Trigger-eval fixture (lightweight, per human ruling):**
  `docs/evals/trigger-prompts.md` with ~10 prompts per skill — explicit
  invocation, implicit ("continue the factory"), contextual, and negative
  controls (ordinary coding requests must NOT trigger `/architect`; narrow
  fact-checks must NOT trigger `/architect-research`) — each with expected
  outcome (triggers / does not trigger). Plus one small optional harness
  script (`skills/architect/trigger-eval.ps1` + `.sh`) that runs the prompts
  through `claude -p` and reports which invoked the Skill tool; manual
  execution, per model generation, referenced from the Maintenance rule.
  Fixture is the deliverable; the harness is best-effort (if `claude -p`
  Skill-invocation detection proves unreliable, the fixture alone ships and
  the harness is recorded as not-viable in the job report — no silent
  fallback).

## Non-goals

- No compression toward 200 lines; no splitting SKILL.md bodies (both inside
  every verified envelope).
- No `disable-model-invocation`, no `when_to_use` adoption (revisit only if
  trigger evals show description-only misses).
- No change to Hard Rules 1–9 substance, skill count, reference depth,
  scripts-for-determinism design, or the cold-judge architecture (all
  validated by the research).
- No re-commit of the r6 report (human ruling: history-only at `0b490f6`;
  this spec is the corrections record).
- No new requirement based on the unverified CRITICAL/MUST-overtrigger claim.

## Assumptions (approve or veto at approval)

- **A1:** Guard cap numbers G4a=1100 and G4b=500 are acceptable revisions of
  the human-ruled P5 budget of 900 — the 900 figure is not sacred, the ~6%
  headroom convention is. Veto → keep 900/trio unchanged and add only G4b–d.
- **A2:** Prescriptiveness-audit deletions (G3) are builder-proposed,
  judge-verified against "no contract/rail deleted", human-visible in the
  closing PR. No separate human ruling per deletion.
- **A3:** The G1 rewrite preserves implicit-trigger UX ("continue the
  factory" routes to `/architect`; research phrasing routes to
  `/architect-research`); the trigger-eval fixture (G5) is the check.
- **A4:** Token counting for G4c uses a deterministic local proxy
  (e.g. words × 1.33), not a tokenizer API dependency.
- **A5:** TOC lines added by G2 count toward the G4 guards and are budgeted
  within the 1100/500 caps.

## Validation strategy

- `tests/validate_skills.py` extended per G4 plus: TOC-presence check for
  every skill reference file >100 non-blank lines; DESIGN.md guard number
  must equal the enforced constant (kills the 800/900 class of drift).
  Full existing validator suite stays green.
- G1: description contains no workflow-stage vocabulary (scout/design/
  verify/synthesize as pipeline narration), retains trigger phrases, ≤1,024
  chars — frozen check greps.
- G2: TOC entries match `##` headings exactly — frozen check script compares.
- G3: judge verifies Hard Rules 1–9 semantics intact and every deletion has a
  justification line; DESIGN.md says 900 (or the approved new cap).
- G5: fixture exists with ≥10 prompts/skill incl. ≥2 negative controls each,
  expected outcomes stated; harness scripts run or are recorded not-viable
  with evidence.

## Domain language

- **Trigger layer** — name+description listing that routes skill invocation;
  distinct from the body. **Trigger-only description** — states what + when,
  never workflow stages. **Prescriptiveness audit** — the F5-criterion pass
  (behavior-changing? contract or prescription?). **Corrections digest** —
  the adversarial-review record above, the durable correction to `0b490f6`.

## Preflight evidence (github mode)

- `gh` 2.96.0 (≥2.94.0) ✓; `gh auth status` logged in as DanMcInerney ✓;
  remote `origin` = github.com/DanMcInerney/architect-loop ✓; main `1b00d8e`
  clean ✓; no `docs/STOP` ✓.

## Open questions (carried, not blocking)

- SKILL.md-length dose-response on Fable-class models: still unmeasured
  anywhere; optional in-run A/B remains available.
- Description A/B (trigger-only vs workflow-summarizing): measurable with
  the G5 fixture before/after G1 lands, if desired.

## Approval record

- (pending)
