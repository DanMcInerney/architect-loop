# Research: agent research-pipeline patterns — what the field does that our loop doesn't

Date: 2026-07-02. Author: architect orchestrator (Claude Fable), from 1 scout +
5 first-wave + 1 expert-wave researcher lanes (codex gpt-5.5/high, live web)
plus orchestrator verification (11 load-bearing sources fetched and checked
this session). Raw lane findings: `.architect/research/r2-*.md` (gitignored).

## The brief

How do frontier labs, production systems, and named experts structure agent
research pipelines — dispatch, coordination, collection, context handling —
and which simple techniques would make a research **skill loop** (the
/architect-research harness, evolved to run like /architect v4: in-session
orchestrator + cold subagents, repo as memory, Claude Code & Codex, no
external infrastructure) faster, simpler, and more token-efficient?

Out of scope (covered by `docs/research/loop-improvements.md`, consumed by
slice `loop-hardening`): judge cadence, spec grilling, slice sizing, stall
signals, tier routing, docs-debt. Filter for every verdict below:
implementable as skill text + cold subagents in the two harnesses. A
technique needing a server, custom runtime, or harness change is a pointer,
not a recommendation.

## Answers first (BLUF)

The current pipeline shape is the field consensus. Orchestrator-worker
fan-out for gathering, single-author synthesis, file-based artifacts,
engineered stop caps — every one of these is independently converged on by
Anthropic, Google, LangChain, and the OSS frameworks, and even the field's
loudest multi-agent critic (Cognition) now endorses exactly this shape
("writes stay single-threaded"). There is no simpler industry-standard
pipeline we are missing. The improvements available are calibrations, not
restructurings.

| # | Verdict | Change | Decisive evidence |
|---|---------|--------|-------------------|
| K1 | KEEP | Orchestrator + parallel cold researchers for gathering; orchestrator alone synthesizes | 5-origin convergence incl. LangChain's measured retreat from parallel writing (VERIFIED) |
| K2 | KEEP | Scale-before-anything tiers (don't fan out on simple questions) | Fan-out yields *negative* returns when a single agent already performs well: ~45% threshold, β=−0.408, p<0.001 (VERIFIED) |
| K3 | KEEP | Hard cap of 2 gap rounds + saturation rule | No measured saturation curve exists anywhere in the field; every production stop rule is an engineered cap (VERIFIED as absence, 2 lanes) |
| K4 | KEEP | File-based lane outputs; raw findings gitignored; committed report as durable memory | Artifact-handoff-over-message-handoff: Anthropic, Manus, LangChain Deep Agents (3 origins, VERIFIED) |
| A1 | ADD | Numeric return cap in the researcher preamble: findings file ≤ ~1,500 tokens (~150 lines) | Anthropic's production contract: subagents spend tens of thousands of tokens, return 1,000–2,000 (VERIFIED); Argus keeps its collector under 21.5K tokens at 64 workers (VERIFIED) |
| A2 | ADD | Draft-as-state gap round: after wave 1 the orchestrator writes a skeleton answer; the *holes in the draft* generate gap lanes; NOT FOUNDs carry forward as a do-not-rechase list | TTD-DR (draft "denoising" drives next queries, VERIFIED mechanism), LangChain brief-reflection, Co-STORM unused-source pool, Manus error retention (3+ origins) |
| A3 | ADD | Calibrate lane budgets in *tool calls* alongside searches, and publish per-tier cost envelopes in the skill | Anthropic's heuristic is per tool call (1 agent/3–10 calls; 2–4 agents/10–15 each; 10+ for complex — VERIFIED); Google publishes ~80 searches/$1–3 standard, ~160/$3–7 max (VERIFIED); Perplexity pins max_steps 10/15 |
| A4 | ADD | Formalize research-as-loop: committed report + its Open-questions section = the research handoff; a later session resumes from it instead of restarting | Durable cross-session state is now first-class: Anthropic memory tool, Claude Code auto-memory, Devin Knowledge (3 origins); our repo-as-memory design already matches |
| D1 | DON'T ADD | No debate, no parallel synthesis, no second orchestration layer, no learned routing | "Architectural bloat": automated MAS underperform CoT-SC at up to 10× cost (VERIFIED); hybrid coordination overhead up to 515% (VERIFIED); codex max_depth 1 already forbids nesting |
| D2 | DON'T ADD | No cache-alignment machinery in lane prompts | Real (10× cached/uncached, VERIFIED) but harness-owned: our ~250-token preamble is below OpenAI's 1024-token cache minimum; cold one-shot lanes have no reusable prefix we control |

## Q1 — When does fan-out pay? (the economics)

The single most cross-validated fact in the corpus, agreed by pro- and
anti-multi-agent camps:

- **Fan-out pays only for breadth-first, decomposable gathering.** Anthropic
  (whose system beat single-agent Opus 4 by 90.2% on their internal research
  eval): "multi-agent systems excel for breadth-first queries"; their own
  caveat — "most coding tasks involve fewer truly parallelizable tasks than
  research" [primary, 2025-06, VERIFIED].
- **It costs real money**: agents ≈ 4× chat tokens; multi-agent ≈ 15× chat
  tokens; token usage alone explains 80% of BrowseComp variance [primary,
  2025-06, VERIFIED]. The quality gain largely *is* token-budget scaling,
  spent in parallel.
- **Where it inverts**: once a single-agent baseline exceeds ~45% on a task,
  coordination yields diminishing-to-negative returns (β=−0.408, p<0.001);
  independent agents amplify errors 17.2×; coordination overhead runs
  58–515% (1.6–6.2× token budgets) ["Towards a Science of Scaling Agent
  Systems", primary, 2025-12, VERIFIED]. Under *equal* token budgets,
  single-agent matches or beats multi-agent on multi-hop reasoning [Tran &
  Kiela, primary, 2026-04, VERIFIED].
- **Parallel search scales when the collector stays small**: Argus reports
  +5.5 points with 1 searcher, +12.7 with 8 (avg of 8 benchmarks), 86.2 on
  BrowseComp with 64 — while the Navigator's context stays under 21.5K
  tokens [primary, 2026-05, VERIFIED; single origin — treat magnitudes as
  the paper's own].

**Implication**: web research at survey scale is squarely inside the
pays-off regime (breadth-first, decomposable, single agent nowhere near 45%
on coverage), so K1 stands. But the inversion evidence makes K2 (scale
tiers; 1 researcher for fact-finds) load-bearing rather than a nicety, and
D1 follows directly: every added coordination layer is measured overhead.
**What would change this**: a measured result showing supervisor-style
research fan-out losing to one long-context agent *at equal budget* on
research (not reasoning) tasks.

## Q2 — Pipeline anatomy: the convergent core

All three labs and all five adopted OSS frameworks share exactly:

1. **Plan → parallel gather → compress/curate → one-pass write.** Google's
   published stages: Plan → Search → Read → Iterate → Output [primary,
   2026-06, VERIFIED]. Anthropic: lead plans to Memory → spawns subagents →
   synthesizes → CitationAgent [primary, 2025-06, VERIFIED].
2. **Writing is never parallel.** LangChain removed parallel section-writing
   after measuring disjoint reports: "Reports were *still* disjoint because
   my sub-agents wrote sections in parallel"; moving writing to a final
   one-shot step put them top-10 on Deep Research Bench [primary, 2025-07,
   VERIFIED]. Matches our "parallelize gathering, never synthesis".
3. **Delegation is a full contract.** Anthropic's fix for duplicate work and
   gaps: each subagent needs "objective, output format, tool/source
   guidance, and boundaries" [primary, 2025-06]. Our lane blocks already
   carry exactly these four.
4. **Citations are a separate cheap pass** (Anthropic CitationAgent; OpenAI
   inline citation annotations in the output array). We fold this into
   verification; at our report sizes a separate pass isn't warranted —
   noted as an option if reports grow.

**Implication**: no structural change. The one calibration the labs publish
that we lack is numeric: see A3.

## Q3 — Result contracts and artifact handoff (token efficiency)

- **Constrain what workers return.** "Each subagent might explore
  extensively, using tens of thousands of tokens or more, but returns only a
  condensed, distilled summary of its work (often 1,000-2,000 tokens)"
  [Anthropic context-engineering, primary, 2025-09, VERIFIED]. Our preamble
  says "compact" but names no number → A1.
- **Files beat messages.** Anthropic: "Subagents call tools to store their
  work in external systems, then pass lightweight references back" [primary,
  2025-06, VERIFIED]. Manus: filesystem as "unlimited, persistent" memory —
  drop page content, keep the URL; drop file content, keep the path
  [primary, 2025-07, VERIFIED]. LangChain Deep Agents mechanized it: tool
  responses >20K tokens offload to disk (path + first 10 lines); at 85% of
  the window, old tool calls truncate to disk pointers; summarize only as
  last resort, keeping the full record on disk [primary, 2026-01, VERIFIED].
  Our `-o` findings-file pattern is this technique; K4 confirmed.
- **Keep failures visible.** Manus: erasing failed actions removes the
  evidence the model needs to not repeat them [primary, 2025-07, VERIFIED].
  Research translation: NOT FOUNDs are anti-repetition state → folded into
  A2 (carry forward as do-not-rechase list).
- **Cache alignment** is the one technique that does not survive our
  constraint filter (D2). It is real — 10× cached/uncached input pricing
  [Manus, VERIFIED]; cache reads 0.1× [Anthropic pricing, primary] — but it
  lives in the harness's system-prompt layout, not in anything a skill text
  controls for cold one-shot `codex exec` lanes. Documented so the next
  reader doesn't re-derive it.
- NOT FOUND (genuine absence): measured comparison of snippet-first vs
  full-page-fetch search discipline. Our snippet-first rule keeps its
  empirical basis from lane deaths observed 2026-06-12, not from
  literature.

## Q4 — Loops, state, and stopping

- **Draft-as-state is the field's gap-round mechanism.** TTD-DR maintains
  "a preliminary draft, an updatable skeleton" iteratively "denoised" by
  retrieval; the evolving draft drives the next queries [primary, 2025-07,
  VERIFIED mechanism; win-rate figures 69.1%/74.5% vs OpenAI Deep Research
  single-origin]. LangChain's supervisor reflects against a compressed
  research brief and spawns more subagents only "until findings sufficiently
  address the research brief" [primary, 2025-07]. Co-STORM persists a mind
  map plus an *unused-sources pool* mined to avoid repetition [primary,
  2024-11]. Our current gap round scores coverage against the brief in the
  orchestrator's head; A2 makes the state explicit and self-steering — a
  skeleton answer whose holes become the gap lanes.
- **Stop rules are engineered caps everywhere.** TTD-DR: max revision steps
  + exit_loop. Co-STORM: user satisfaction / 30-query cap. LangGraph
  reflection: MAX_ITERATIONS = 5. GPT Researcher: breadth 4 / depth 2.
  Nobody publishes a benefit-of-round-N+1 curve (hunted by two lanes; NOT
  FOUND). K3 stands: our 2-round hard stop is as principled as anything in
  production.
- **Durable cross-session research state is now first-class**: Anthropic
  memory tool (files in `/memories` read just-in-time across sessions),
  Claude Code auto-memory, Devin Knowledge [all primary, 2026 docs]. A4:
  the committed report's Open-questions section is already written as "the
  next round's input" — name it the research handoff, so a later session
  grounds from it exactly as /architect grounds from `docs/HANDOFF.md`.

## Expert positions map (opinions, not facts)

- **Walden Yan (Cognition, CPO — talks his book)**: 2025 "Don't Build
  Multi-Agents" → 2026 "Multi-Agents: What's Actually Working": now ships
  multi-agent, but "writes stay single-threaded"; swarms remain "mostly a
  distraction" [2026-04, two lanes independently consistent]. His accepted
  shapes — clean-context review loops, manager/child map-reduce — are our
  judge and lane patterns respectively.
- **Lance Martin (LangChain)**: fan out for context gathering, never
  writing; "remove structure as models improve"; write/select/compress/
  isolate taxonomy [2025-06/07, primary].
- **Harrison Chase (LangChain, CEO — framework interest)**: the debate is
  mis-framed; the hard problem is "controlling what context the model sees",
  and subagents are a context-isolation tool. Deep agents = detailed prompt
  + planning tool + subagents + filesystem [2025-07, primary]. Our loop has
  all four.
- **Simon Willison (independent)**: moved from skeptical to "OK, I'm sold"
  on research fan-out specifically [2025-06]; still warns against splitting
  into dozens of specialists; subagents' main value is "preserving root
  context" [2026-03 guide].
- **Andrew Ng (educator/course interest)**: multi-agent collaboration stays
  a core pattern; biggest predictor of success is disciplined evals/error
  analysis [2025-10].
- **Where credible experts still disagree**: Ng teaches multi-agent
  collaboration broadly; Yan/Martin restrict it to read-side work. The
  disagreement is about *write-side* parallelism only — read-side fan-out
  has no credible detractor left as of mid-2026.

## Open questions

1. Argus's small-collector result (21.5K navigator context at 64 workers) is
   single-origin. Resolve: replicate at our scale — measure orchestrator
   context growth per collected lane at A1's return cap.
2. Does draft-as-state (A2) measurably beat coverage-scoring gap rounds at
   our scale? Resolve: run both on one real research topic; compare gap-lane
   precision (fraction of gap findings that enter the final report).
3. MAST category percentages (41.8/36.9/21.3) and TTD-DR win rates are
   lane-quoted from paper bodies, unverified in abstracts. Low stakes for
   our decisions; re-fetch bodies if ever load-bearing.
4. Per-round diminishing-returns curves remain unmeasured field-wide. Our
   2-round cap is defensible but evidence-free either way.

## Method

1 scout mapped terrain → orchestrator designed 5 first-wave lanes along the
scout's fault lines (production anatomy, token efficiency, OSS frameworks,
adversarial counter-case, loop/state) → 1 second-wave expert lane with
roster extracted from wave-1 findings. All lanes codex exec gpt-5.5/high,
read-only, live web, 15-search budgets, ≤5 subjects. Orchestrator fetched
and verified 11 load-bearing sources directly (all VERIFIED tags above);
claims marked single-origin were not independently confirmable. Adversarial
coverage was structural: lane 4's entire mandate was falsifying our current
design.

## Key citations (fetched this session or by a lane; dated; tiered)

- Anthropic, "How we built our multi-agent research system" [primary,
  2025-06-13, fetched+verified] — 90.2%, 4×/15×, 80% variance, effort
  heuristic, external-artifact refs, CitationAgent, 90% time cut.
- Anthropic, "Effective context engineering for AI agents" [primary,
  2025-09-29, fetched+verified] — 1,000–2,000-token subagent returns,
  just-in-time context, compaction semantics.
- Manus, "Context Engineering for AI Agents" [primary, 2025-07-18,
  fetched+verified] — KV-cache 10×, filesystem-as-memory, todo recitation,
  error retention.
- LangChain, "Context Management for Deep Agents" [primary, 2026-01-28,
  fetched+verified] — 20K offload, 85% truncation, dual summary record.
- Lance Martin, "The Bitter Lesson of Agent Building" [primary, 2025-07-30,
  fetched+verified] — parallel-writing retreat, one-shot final write.
- Google, Gemini Deep Research API docs [primary, 2026-06-26,
  fetched+verified] — budgets ~80/$1–3 and ~160/$3–7, 60-min cap,
  collaborative planning, Plan→Search→Read→Iterate→Output.
- "Towards a Science of Scaling Agent Systems", arXiv:2512.08296 [primary,
  2025-12-09, fetched+verified] — +80.9%/−70.0%, ~45% threshold, 17.2×
  error amplification, 58–515% overhead.
- Tran & Kiela, "Single-Agent LLMs Outperform Multi-Agent Systems…",
  arXiv:2604.02460 [primary, 2026-04, fetched+verified] — equal-budget
  parity/win for single agent on multi-hop reasoning.
- "The Illusion of Multi-Agent Advantage", arXiv:2606.13003 [primary,
  2026-06-11, fetched+verified] — architectural bloat; CoT-SC beats
  automated MAS at up to 10× less cost.
- Argus, "Evidence Assembly for Scalable Deep Research Agents",
  arXiv:2605.16217 [primary, 2026-05-15, fetched+verified, single-origin]
  — +5.5/+12.7 parallel-searcher scaling; navigator <21.5K tokens.
- TTD-DR, "Deep Researcher with Test-Time Diffusion", arXiv:2507.16075
  [primary, 2025-07-21, fetched; mechanism verified, figures single-origin].
- Cemri et al., MAST, arXiv:2503.13657 [primary, 2025-03, fetched; taxonomy
  verified, percentages single-origin].
- Cognition: "Don't Build Multi-Agents" [primary, 2025-06-12, lane-fetched
  ×2] and "Multi-Agents: What's Actually Working" [primary, 2026-04-22,
  lane-fetched ×2] — single-threaded writes; accepted multi-agent shapes.
- LangChain, "Open Deep Research" [primary, 2025-07-16, lane-fetched] —
  Scope→Research→Write; supervisor reflection against the brief.
- Co-STORM, EMNLP 2024 [primary, 2024-11, lane-fetched] — mind-map state,
  unused-source pool, turn policy.
- Willison: agent-definitions tag, subagents guide, parallel-agents post
  [primary, 2025-06→2026-03, lane-fetched] — positions as dated opinions.
- HF Open Deep Research [primary, 2025-02-04, lane-fetched] — GAIA 55.15%
  code-agent vs 33% JSON-tool-calling.
- GPT Researcher docs/repo, dzhng/deep-research, STORM repo/PyPI
  [primary, 2025–2026, lane-fetched] — breadth/depth defaults, <500-LoC
  minimalism, adoption figures.
