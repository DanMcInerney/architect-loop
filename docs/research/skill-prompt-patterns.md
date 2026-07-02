# Skill-prompt patterns worth stealing: design quality for architect v5

Research handoff, 2026-07-02 (r4 pass). Raw findings: `.architect/research/r4-*`
(gitignored). Sources: compound-engineering plugin (EveryInc), obra/superpowers
v6.1.0, mattpocock/skills (raw SKILL.md files), gstack skills read locally
(orchestrator, plan-eng-review, tdd, design-an-interface,
improve-codebase-architecture), Beck/Ousterhout primary sources.

## The brief

Read the leading engineering-skill systems and extract what makes them work,
so the v5 brain designs specs and issues to high software-architecture
standards: correct abstraction of core concepts, no technical debt in
fundamental abstractions, "first make the change easy, then make the easy
change" (Beck), simplicity as the ruling constraint.

## Answer first

The five systems converge on the same meta-lesson: **design quality is
enforced at plan time with named, checkable rules — not requested at review
time with adjectives.** Every system that produces good architecture gives
the model a small vocabulary (deep/shallow, seam, leverage, locality), a
handful of falsifiable tests (deletion test, seam rule, RED-before-GREEN
evidence), and structural separation of concerns in the work items
themselves (structural vs behavioral, WHAT vs HOW). The steals below are
ranked by how directly they serve the v5 brief.

## What to steal (verified against primary sources)

### S1. The oddity rule — root-cause design over patching [multi-source]

- superpowers `systematic-debugging`: "NO FIXES WITHOUT ROOT CAUSE
  INVESTIGATION FIRST"; after 3 failed fixes, stop and **question the
  architecture** rather than attempt fix #4.
- gstack `orchestrator`: "If a task is really a workaround for an
  architecture problem, surface that in the plan instead of burying it."
- Balanced by Pocock `codebase-design`'s conservative seam rule: "Don't
  introduce a seam unless something actually varies across it"; "One adapter
  means a hypothetical seam. Two adapters means a real one."
- **v5 form**: when a lane hits an oddity/special case, the brain classifies
  before dispatching a fix: (a) local wart, patch it, note it; (b) second
  occurrence of a variation → a REAL seam exists → emit a structural issue
  that abstracts it, then the easy change. The classification is recorded on
  the issue. Exact phrase "abstract the oddity" appears nowhere in the
  field (NOT FOUND) — the mechanics above are its established equivalents.

### S2. Beck / tidy-first as DAG structure [primary, 2012 + operationalized 2025-26]

- Beck (X, 2012-09-25): "for each desired change, make the change easy
  (warning: this may be hard), then make the easy change."
- Tidy First: structural (behavior-preserving) and behavioral changes get
  separate commits/reviews; agent systems now encode this as separate
  commit/command paths.
- gstack `plan-eng-review` cognitive pattern #13: "Refactor first, implement
  second. Never structural + behavioral changes simultaneously."
- **v5 form**: at decomposition, when a feature requires making the change
  easy first, the brain emits a *structural issue* (refactor,
  behavior-preserving, gates = existing tests still green) with a blocking
  edge to the *behavioral issue*. One lane never mixes both kinds.

### S3. Deep-module vocabulary + design-it-twice for load-bearing abstractions [primary]

- Pocock `codebase-design`: "a lot of behaviour behind a small interface";
  shallow = "interface nearly as complex as the implementation"; heuristics:
  fewer methods? simpler parameters? hide more complexity? the deletion test
  (would deleting it concentrate complexity or just move it?); "the
  interface is the test surface." Rejects the literal lines-ratio depth
  metric ("rewards padding") for depth-as-leverage.
- Ousterhout "design it twice" encoded as parallel design: 3+ subagents
  forced into radically different interface shapes ("different layout,
  different information hierarchy… not just different colours" — same rule
  for UIs), compared on depth, locality, seam placement, misuse-resistance.
- **v5 form**: intake/decomposition must name the spec's fundamental
  abstractions. Each NEW load-bearing abstraction (a module other issues
  will build on) gets design-it-twice: 2-3 radically different interface
  sketches (cheap parallel subagents), brain picks with recorded rationale.
  Existing or leaf-level code does NOT trigger this — simplicity.

### S4. Scope challenge before decomposition [gstack, local primary]

`plan-eng-review` Step 0, applied before any issue is cut: what existing
code already solves each sub-problem; the minimum change set for the stated
goal; complexity smell at >8 files or >2 new classes/services per issue;
search for framework built-ins before building; boring by default
(innovation tokens); essential vs accidental complexity (Brooks).

### S5. Interface handoff blocks in work items [superpowers, primary]

`writing-plans`: the implementer "may see only its own task," so every task
carries an `Interfaces` block — exact function names, parameter types,
return types it consumes and produces. **v5 form**: any issue producing a
surface another issue consumes states that interface verbatim in its body;
the consumer issue references it. This is what makes disjoint parallel
lanes COMPOSE, not just avoid conflicts.

### S6. Evidence artifacts over trust [superpowers + compound-engineering, primary]

- superpowers implementer reports carry a `TDD Evidence` section: RED
  command + failing output + why the failure was expected; GREEN command +
  passing output. The reviewer inspects the artifact, not the claim.
  TDD enforced "with deletion, not reminders": code written before its test
  is deleted, not retrofitted.
- Pocock `tdd`: the horizontal-slice anti-pattern — never all-tests-then-
  all-code; tracer bullets, one test → one impl; never refactor while RED;
  tests through public interfaces only ("test would survive internal
  refactor").
- compound-engineering: subagents return artifact PATHS, never long inline
  prose ("long inline subagent outputs sometimes collapsed into summaries
  and became unrecoverable") — independent confirmation of our lane-report-
  file discipline.

### S7. The codify/compound step [compound-engineering, primary]

`ce-compound` writes one structured solution doc per resolved problem to
`docs/solutions/` (bug track: Problem / Symptoms / What Didn't Work /
Solution / Why This Works / Prevention), updates the domain glossary when
new terms surfaced, and makes small instruction-file edits only for
discoverability. Only the orchestrator writes tracked docs. Will Larson
[med, 2026-01]: the compound step is "a structured wiki consulted by future
plan iterations"; adopting the whole pattern took "about an hour."
**v5 form**: nontrivial diagnoses (a blocker the brain solved, an oddity
ruling, a what-didn't-work) get a `docs/solutions/<slug>.md` at the docs
lane / PR boundary, and future intake reads `docs/solutions/` during
grounding. Lessons die in chat otherwise.

### S8. Reviewer calibration [gstack orchestrator, local primary]

"Flag only gaps that affect correctness, the stated requirements, or
documented project invariants — cite file:line evidence for every finding.
Do not report stylistic preferences. An uncalibrated reviewer always finds
something; that spirals into over-engineering." Goes verbatim into judge /
cross-review prompts.

### S9. Richer parallel-safety check [compound-engineering, primary]

`ce-work`'s conflict test goes beyond file overlap: shared APIs, migrations,
generated artifacts, lockfiles, config/schema, dev servers, databases,
installs, rate limits. Cap "about 3-5 workers" — third independent
confirmation of the 3-5 range (with Claude docs and Osmani).

### S10. Skill-writing craft (for v5's own text) [Pocock + superpowers, primary]

- "A skill exists to wrangle determinism out of a stochastic system" —
  predictability over prose. Every word costs context; no-op test: "does a
  line change behaviour versus the default?" — prune lines that don't.
- Descriptions state what the skill is + the trigger branches — never
  summarize the workflow (agents that think they know the workflow skip
  reading the body — Vincent, 2025-10).
- Each step ends on a checkable completion criterion. Progressive
  disclosure: SKILL.md top stays legible; reference moves behind pointers
  (matches our existing dispatch.md/loop.md split).
- superpowers `writing-skills`: no skill without a failing pressure test
  first (we already do this — grill validated itself on first use).
- Failure mode to avoid: compound-engineering's 36k-token always-loaded
  footprint (GitHub issue #63) — validates our 800-line size guard.

### S11. Domain language + sparse ADRs [Pocock, primary]

`domain-modeling`: sharpen terms during design, update the glossary
(`CONTEXT.md`) the moment a term resolves; issues and interfaces use domain
names, not `FooBarHandler`. ADRs only when ALL THREE hold: hard to reverse,
surprising without context, result of a real trade-off — otherwise skip.
(ADRs = decisions future architecture passes must not re-litigate.)

## Cross-system disagreements (minor)

- superpowers brainstorming asks questions ONE at a time; Spec Kit also
  sequential; our v5 chose one batch — still an open empirical question
  (carried from r3; unchanged).
- superpowers evolved from two separate reviewers (spec, quality) to ONE
  reviewer returning two verdicts (v4 release note vs current main) —
  supports our single cold judge returning per-gate + diff-vs-intent
  verdicts rather than adding a second reviewer role.
- Skill length: Pocock governs qualitatively ("sprawl"), we govern with a
  hard 800-line guard — keep ours (checkable beats qualitative).

## Open questions

1. Does design-it-twice on fundamental abstractions measurably reduce
   rework in our loop? Log rework-per-issue with/without it during dogfood.
2. `docs/solutions/` retrieval: grounding reads it — at what repo size does
   it need an index? Defer until it hurts.

## Key citations

- obra/superpowers v6.1.0 skill files [primary, 2026-06-30] — https://github.com/obra/superpowers
- EveryInc/compound-engineering-plugin skill files [primary, 2026-07] — https://github.com/everyinc/compound-engineering-plugin
- mattpocock/skills codebase-design, domain-modeling, writing-great-skills [primary, 2026-07] — https://github.com/mattpocock/skills
- Kent Beck, original "make the change easy" post [primary, 2012-09-25] — https://x.com/KentBeck/status/250733358307500032
- Will Larson on compound engineering adoption [med, 2026-01-19] — https://lethain.com/everyinc-compound-engineering/
- gstack skills read locally: orchestrator, plan-eng-review, tdd,
  design-an-interface, improve-codebase-architecture [primary, local install]
