# Agent skill design: what the field actually recommends, and what holds for Fable-class models

Research handoff, 2026-07-04 (r6 pass). Raw findings: `.architect/research/r6-*`
(gitignored). Orchestrator verified every load-bearing claim against the
primary source by direct fetch this session.

## The brief

A widely repeated community rule says keep SKILL.md under ~200 lines and split
the rest into reference files. Is that true or best practice? Does it hold for
Fable-class models? Read the general expert/company advice (Anthropic, OpenAI,
practitioners) on building skills, and derive what architect-loop should
improve. Decision informed: whether/how to restructure architect-loop's skills.

## Answer first

**The 200-line rule is folk canon, not official guidance or measured fact.**
The official ceiling — identical in Anthropic's authoring docs and the
agentskills.io open spec — is **"Keep SKILL.md body under 500 lines"** /
**< 5,000 tokens**, with reference files one level deep. OpenAI's Codex docs
set **no body size limit at all**. The 200-line figure traces to influencer
posts (clearest: Akshay Pachaar, 2026-05-01, with unverifiable activation
stats), plus practitioner rules-of-thumb that are even stricter (superpowers:
"<200 words total" for frequently-loaded skills).

**But the direction it points survives the evidence check, with a twist.**
SkillsBench v4's ablation (2026-06): compact skills +19.0pp, standard-length
+21.5pp, detailed +14.5pp, **comprehensive +0.7pp** — exhaustive skills are
nearly worthless, but *standard-length beats compact*, so maximal compression
also loses. The paper's advice: "optimize for verifier-facing detail an agent
cannot infer, not for completeness."

**For Fable-class models the rationale shifts, not the practice.** The
instruction-following ceiling moved (~200–300 simultaneous constraints in
2025 → ~2,000 in a 2026 replication, GPT-5.5 best), so "the model can't read
past line 200" is obsolete. What replaces it, per BOTH vendors' official
frontier-model guidance: (a) **over-prescription now degrades output** —
Anthropic: "Skills developed for prior models are often too prescriptive for
Claude Fable 5 and can degrade output quality"; OpenAI: shorter, outcome-first
prompts beat process stacks, and contradictions burn reasoning tokens; (b)
**context economics stayed** — listing budgets, compaction reattach limits,
and the window shared with actual work. No controlled SKILL.md-length
dose-response on Fable 5/GPT-5.5 exists (verified NOT FOUND).

**The evidence says the real fragility is the trigger layer, not body
length.** Documented production failures cluster at descriptions: misses,
overtriggers, listing-budget truncation. Size the description, count of
installed skills, and always-loaded footprint before worrying about body
lines 200–500.

## Verified findings

### F1. The official rule set (VERIFIED, primary, fetched 2026-07-04)

- Anthropic best-practices: "Keep SKILL.md body under 500 lines for optimal
  performance"; split when approaching the limit; references **one level
  deep** from SKILL.md (nested refs get partially read via `head -100`);
  reference files **>100 lines need a table of contents**; description ≤1024
  chars, third person, states what + when with trigger keywords; name ≤64
  chars, gerund form; "The context window is a public good"; "Default
  assumption: Claude is already very smart — only add context Claude doesn't
  already have."
- Loading model: L1 metadata (~100 tok/skill, always), L2 body (on trigger),
  L3 files (on demand); scripts execute without entering context.
- **Degrees of freedom**: match specificity to fragility — high freedom
  (heuristics) for context-dependent judgment, low freedom (exact scripts,
  "do not modify the command") for fragile/must-be-consistent operations.
  This is the official frame for when hard rails are correct.
- Claude Code specifics: skill descriptions are shortened to fit **1% of the
  context window**; `description + when_to_use` truncates at **1,536 chars**
  per listing entry; after compaction only the **first 5,000 tokens per
  invoked skill** reattach, under a **25,000-token combined** budget;
  `disable-model-invocation: true` removes the description from context
  entirely.
- agentskills.io spec (same numbers; "originally developed by Anthropic",
  open standard): body has "no format restrictions"; instructions < 5,000
  tokens recommended; "Keep your main SKILL.md under 500 lines."
- OpenAI Codex: same SKILL.md format (adopted the open standard); initial
  skill list capped at **2% of context or 8,000 chars** (descriptions
  shortened first, then skills omitted with a warning); **no documented body
  size limit**; AGENTS.md is the always-loaded counterpart, default cap
  32 KiB. [All primary; platform.claude.com, code.claude.com,
  agentskills.io, developers.openai.com, 2026-07]

*Implication:* architect's SKILL.md (253 lines, ~3.5k tok) is inside every
official envelope, including the 5k-token compaction reattach. *Would change
this:* an official revision of the 500-line figure, or a measured cliff below
it.

### F2. Size evidence: the cliff is "comprehensive", not line 200 (VERIFIED)

- SkillsBench v4 [primary, 2026-06-14, arXiv:2602.12670]: curated skills
  +16.6pp average pass rate (33.9%→50.5%, range +4.1..+25.7 across 18
  configs). Ablations: 1 skill +18.0pp, 2–3 skills +19.0pp, **≥4 skills
  +10.1pp**; compact +19.0, **standard +21.5**, detailed +14.5,
  **comprehensive +0.7pp**. "Focused procedural guidance beats exhaustive
  prose." Caveat the paper itself states: length is confounded with content;
  length-matched baselines are future work. Also: self-generated skill packs
  *underperformed no-skills by 8.1–11.5pp*, and in a trajectory audit 10/12
  solver runs never read them — skills are not free wins.
- SkillJuror [primary, 2026-06-10, arXiv:2606.11543]: cleanest progressive-
  disclosure test — knowledge held fixed, GPT-5.4, 82 tasks: +4.1% strict
  pass for split-into-references vs flat, but resources actually touched rose
  1.18→3.85 per trajectory. Structure changes agent *behavior* strongly and
  *outcomes* modestly; it also underperformed on 15/82 tasks.
- Counter-case: Trace2Skill [primary, 2026-03] consolidates one comprehensive
  skill per domain — but still routes quirks into 13 reference files;
  "structured hierarchy," not one big flat file.
- Instruction-count ceiling: IFScale [primary, 2025-07] — frontier models
  ~68% accuracy at 500 simultaneous instructions, earlier-instruction bias;
  Arize replication [med, 2026-06] — boundary moved to ~2,000 constraints,
  "GPT-5.5 does the best." Long-context: length alone measurably hurts even
  with perfect retrieval [primary, 2025-10]; "context rot" across 18 LLMs
  [med, 2025-07].
- **NOT FOUND** (verified): any controlled token-length dose-response for
  SKILL.md on Fable 5 or GPT-5.5. The "old limits are obsolete" claim is
  extrapolation from constraint benchmarks, not direct measurement.

*Implication:* aim for standard-length focused bodies; never ship exhaustive
ones; keep skill count per task ≤3. Don't over-compress to chase 200 lines —
compact measurably underperforms standard. *Would change this:* a
length-matched SkillsBench successor isolating size on Claude 5-class models.

### F3. The 200-line rule's actual origin (community, low confidence by nature)

Akshay Pachaar, X/LinkedIn 2026-05-01: "The 500-line cap is a maximum, not a
target… Past 200 lines, instructions at the bottom get ignored," plus
unverified claims (directive descriptions "100% activation" vs 37% passive).
Carl Vellotti: "100 lines, maybe 200." A GitHub wiki repeats it. No official
source, no published measurement behind the specific number. superpowers'
current authoring skill is stricter still and word-based: heavy reference
(100+ lines) goes to separate files; "frequently-loaded skills: <200 words
total, other skills: <500 words." [r6-05 S1–S4; obra docs VERIFIED]

*Implication:* treat 200 as one practitioner's Schelling point inside the
official 500 envelope — not a rule to enforce. The earlier-instruction bias
(IFScale) gives it a grain of truth for older models.

### F4. The trigger layer is where skills actually fail (high confidence)

Production failure reports (GitHub issues, all primary, dated 2025-12..2026-05):

- Description miss despite near-exact wording match (claude-opus-4-5,
  anthropics/claude-code#20986).
- Overtrigger: Anthropic's own 590-line docx skill fired on `.md` tasks via
  broad terms like "report", "memo" (#43259).
- **Listing-budget truncation**: 153 installed skills → ~36 descriptions
  silently dropped, killing auto-trigger (#59921).
- Skill()-bypass: model reads SKILL.md/references as plain files instead of
  invoking (#57790, Opus 4.7 1M).
- Codex: no per-request opt-out of auto-triggered skills (#17085); skill
  conventions colliding with repo reality (jj vs git, #16127); in-skill
  subagent instructions ignored (#23496); bundled script not found (#8364).

Vendor guidance agrees the description is the routing surface: Codex calls
`description` "the primary trigger signal"; Anthropic's Opus 4.5+/Fable
guidance says aggressive trigger language (`CRITICAL: You MUST use…`) now
**overtriggers** — write plain "Use when…". superpowers' rule: the
description states **only triggering conditions, never the workflow** —
a workflow summary teaches the model to skip reading the body. [VERIFIED]

*Implication:* description quality and installed-skill count dominate
real-world reliability. Skills are context, not execution guarantees — a
skill's hard invariants need enforcement outside the prompt (validators,
scripts, frozen checks) if they must hold.

### F5. Writing for frontier models: both vendors, same message (primary)

- Anthropic (Fable 5 guide, VERIFIED verbatim): "Skills developed for prior
  models are often too prescriptive for Claude Fable 5 and can degrade output
  quality. Review and consider removing older instructions if default
  performance is better." Also: never instruct the model to echo internal
  reasoning (triggers `reasoning_extraction` refusals); fresh-context
  verifier subagents outperform self-critique; capability jumps are the cue
  to re-evaluate which instructions/guardrails are still needed.
- OpenAI (GPT-5.5 prompt guidance): "Shorter, outcome-first prompts" beat
  process-heavy stacks; don't carry over every old instruction;
  contradictory instructions are *more* damaging on reasoning models
  (reasoning tokens spent reconciling them) — but coding workflows still
  need explicit output contracts, acceptance criteria, continue-vs-ask rules.

*Implication:* per-model-generation pruning (architect's existing Maintenance
rule) is now vendor-official on both sides. The thing to delete is
*prescription of process*; the thing to keep is *contracts, boundaries, and
fragile-operation rails* (Anthropic's low-freedom category).

### F6. Expert positions map (opinion class; COI flagged)

- **Simon Willison** (independent): skills "maybe a bigger deal than MCP"
  [2025-10-16]; MCP "may be a one-year wonder" since agents drive CLIs
  [2025-12-31]. No 2026 reversal found.
- **Anthropic skill team** (Barry Zhang, Keith Lazuka, Mahesh Murag; vendor):
  progressive disclosure is "the core design principle"; bundled context
  "effectively unbounded" given filesystem+execution. Small means small
  *loaded* footprint, not small skill package.
- **Jesse Vincent / superpowers** (author-promoter): skill TDD — "NO SKILL
  WITHOUT A FAILING TEST FIRST," applying to *edits* too; pressure scenarios
  with subagents, baseline without the skill, capture rationalizations.
  v6.1.1 (2026-07-02) moved skills to a separate auto-updating repo — a
  large *ecosystem* of individually small skills.
- **Matt Pocock** (sells courses/promotes own repo): "Skills don't have to be
  long to be impactful" (/grill-me is 3 sentences); flipped most skills to
  `disable-model-invocation: true` and measured a **63% cut in
  skill-description tokens** [2026-06-18]; principle: "the user stays in
  control, not the agent."
- **HumanLayer (Kyle)** (vendor): frontier thinking models follow "~150–200
  instructions" with reasonable consistency; CLAUDE.md consensus <300 lines;
  theirs <60.
- **Sharpest live disagreement:** invocation policy — model-discovered
  (Anthropic, superpowers) vs user-invoked-by-default (Pocock). Genuinely
  open; depends on skill count and tolerance for mistriggers.
- **NOT FOUND:** any credible expert arguing against progressive disclosure
  or for "one big file, the model handles it." The counter-position does not
  exist in the discourse; only degrees of splitting are debated.

### F7. Placement consensus (community, converging)

AGENTS.md/CLAUDE.md = small always-loaded durable contract (Codex caps it at
32 KiB; community: <300 lines). Skills = on-demand reusable procedures.
Subagents = isolated context-heavy work. MCP = live external systems.
Plugins = distribution. Everything else behind progressive disclosure.

## What this means for architect-loop (prioritized)

Local audit (this session): `skills/architect/SKILL.md` 253 lines / ~3.5k
tok; `dispatch.md` 675 lines / ~8.9k tok (on-demand, section-pointer
addressed); `loop.md` 120; combined guard 849/900 non-blank. Two skills total.

1. **Fix `/architect-research`'s description — it violates the strongest
   consensus rule.** It summarizes the workflow (scout → design → verify →
   synthesize) instead of stating trigger conditions. Vendor + superpowers +
   our own r4 finding agree this trains body-skipping and wastes listing
   budget (1,536-char truncation; 1% window). Rewrite as trigger-only.
   `/architect`'s description is already trigger-only — keep.
2. **Add a table of contents to `dispatch.md`** (675 lines; official rule:
   reference files >100 lines need a TOC because partial reads happen).
   `loop.md` (120) gets a 3-line TOC too. Cheap, directly evidence-backed.
3. **Run the Fable-era prescriptiveness audit as a one-time pass, then keep
   the Maintenance rule.** Test each line with the official criterion: does
   it change behavior vs the model's default, and is it a contract/rail
   (keep) or process prescription (candidate to delete)? Specifically scan
   for: aggressive trigger wording (`CRITICAL`/`MUST` in
   descriptions — overtriggers on Opus 4.5+/Fable), echo-your-reasoning
   instructions (refusal risk on Fable), and contradictions between
   SKILL.md, dispatch.md, and loop.md (contradictions now cost reasoning
   tokens). Hard Rules 1–9 are low-freedom rails around fragile operations —
   the official degrees-of-freedom frame says those stay.
4. **Keep the 900-line guard; update its recorded rationale.** The evidence
   cliff is "comprehensive/exhaustive" content and skill count — not line
   200. Standard-length beats compact (+21.5 vs +19.0pp), so do NOT compress
   toward a 200-line target; prune by the no-op test instead. Add one
   sub-rule: SKILL.md body stays **< 5,000 tokens** so it reattaches whole
   after compaction during long factory runs (currently ~3.5k — headroom,
   not a change).
5. **Add a small trigger-eval suite** (new practice both vendors converged
   on): ~10 prompts per skill — explicit invocation, implicit ("continue the
   factory"), contextual, and negative controls (ordinary coding requests
   must NOT trigger /architect) — runnable manually or via the validator.
   Anthropic: build evals before docs, 3 scenarios minimum, baseline without
   the skill; OpenAI: 10–20 prompts incl. negative control. We already do
   pressure-testing at the grill; this extends it to the trigger layer,
   where the field's documented failures actually live.
6. **Validated, no change:** scripts-for-determinism (check-runner,
   preflight/postflight, status, watchdog match "prefer scripts for
   deterministic operations; execute without loading into context");
   references one level deep; two-skill footprint (SkillsBench: 1–3 optimal);
   repo-level enforcement of invariants outside prompts (F4); cold
   fresh-context judge (Fable guide explicitly: fresh verifier subagents >
   self-critique).
7. **Not adopted:** `disable-model-invocation` (Pocock's 63% saving matters
   at 19+ skills; we have 2, and "continue the factory" implicit triggering
   is core UX). Splitting SKILL.md below its 253 lines (evidence says
   standard-length is the sweet spot; it's inside every envelope).

## Open questions

1. No SKILL.md-length dose-response on Fable 5/GPT-5.5 exists. Resolve by:
   watching SkillsBench successors for length-matched ablations, or running
   our own A/B during a factory run (same slice, 253-line vs pruned-150-line
   SKILL.md, compare judge FAIL/respawn counts).
2. Does trigger-only vs workflow-summarizing description measurably change
   invocation? Testable with the #5 trigger suite before/after the
   `/architect-research` description rewrite.
3. Invocation-policy dispute (model-discovered vs user-invoked default):
   revisit if the repo's skill count ever grows past ~5.
4. `when_to_use` frontmatter (Claude Code-only) — worth adopting if trigger
   evals show description-only misses.

## Key citations

- Anthropic, Skill authoring best practices [primary, fetched 2026-07-04] —
  https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Anthropic, Prompting Claude Fable 5 [primary, fetched 2026-07-04] —
  https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
- Agent Skills specification [primary, fetched 2026-07-04] —
  https://agentskills.io/specification
- OpenAI, Codex Skills docs [primary, fetched 2026-07-04] —
  https://developers.openai.com/codex/skills
- OpenAI, skill eval guide [primary, 2026-01-22] —
  https://developers.openai.com/blog/eval-skills
- SkillsBench v4 [primary, 2026-06-14] — https://arxiv.org/abs/2602.12670
- SkillJuror [primary, 2026-06-10] — https://arxiv.org/abs/2606.11543
- IFScale [primary, 2025-07-15] — https://arxiv.org/abs/2507.11538; Arize
  2026 replication [med, 2026-06] —
  https://arize.com/blog/llm-instruction-following-benchmark-2026/
- obra/superpowers v6.1.1 writing-skills [primary, 2026-07-03] —
  https://raw.githubusercontent.com/obra/superpowers/v6.1.1/skills/writing-skills/SKILL.md
- Anthropic engineering, Equipping agents for the real world [primary,
  2025-10-16/upd 2025-12-18] —
  https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- Pocock, skills changelog v1 (63% figure) [primary, 2026-06-18] —
  https://www.aihero.dev/skills/skills-changelog-v1-announcement
- Pachaar 200-line post [low, 2026-05-01] —
  https://x.com/akshay_pachaar/status/2050201509821063576
- Claude Code issue set (trigger failures) [primary, 2026-01..05] —
  anthropics/claude-code #20986, #43259, #59921, #57790; openai/codex
  #17085, #16127, #23496, #8364
- HumanLayer, writing a good CLAUDE.md [med, 2025-11-25] —
  https://www.humanlayer.dev/blog/writing-a-good-claude-md
