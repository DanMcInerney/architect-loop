# Research: Architect Loop improvements — cadence, spec-grilling, teardowns, failure-masking

Date: 2026-07-02. Method: 5 parallel Sonnet researcher lanes (budgeted,
saturation-ruled), orchestrator verification pass (3 load-bearing claims
re-fetched from primary sources this session). Raw findings:
`.architect/research/01-05*.md` (gitignored). No code changes made — this is
the decision report.

## The brief

Keep the orchestrator ("brain") token-thin, output quality high, speed high,
simplicity maximal. Answer with evidence: (1) judge cadence — incremental
per-worker vs one batch review + rework loop; (2) where adversarial review of
the slice spec pays most, especially first-time in an unfamiliar repo;
(3) what comparable loop systems have that we lack / proved unnecessary;
(4) SOTA lab practices with benchmarks; (5) ban silent fallbacks and
unrequested backwards-compatibility shims?

## Answers first (BLUF)

1. **Judge cadence: neither extreme — the unit of judgment is the SLICE,
   judged immediately after its lanes integrate, before anything builds on
   it.** Keep per-lane checks mechanical (post-flight), not judge calls. The
   real lever the evidence supports: **keep judged diffs small** (~≤400
   changed lines is where both human-review and LLM-context evidence
   agree effectiveness collapses). Batching multiple slices into one giant
   review is contraindicated by four independent evidence lines; per-lane
   judge invocations are unnecessary token spend for disjoint lanes that
   share one frozen gate file.
2. **Adversarial spec review pays most as ONE fresh-context, repo-grounded
   grill of the draft gate file BEFORE freezing** — not more post-build
   review, and not more same-session self-checking (which measurably makes
   things worse). First-time-in-a-repo, the grill must be *mechanical*:
   actually run the verify commands and check the file paths the spec
   assumes. PHASE 0 stays (different failure class), but it fires after
   freeze — too late to fix a defective gate cheaply (observed twice in this
   repo's own history today: the repo-name grep collision and the VG7
   judge-sequencing miss would both have been caught by a pre-freeze grill).
3. Teardowns of 11 systems mostly **confirm the current design** (gates
   before work, cold review, repo-as-memory, discard-over-rescue, hard
   merge gates) and contribute three cheap additions: repeated-identical-
   action stall detection, a mechanical/judgment review split, and an
   instruction-budget ceiling on skill text.
4. Lab evidence quantifies what the loop already assumes — and flags one
   real dispute (Anthropic pro-multi-agent vs Cognition anti-, for coding)
   that our disjoint-file-set design largely sidesteps.
5. **Yes — ban both**, with one scoped exception (explicitly-specced
   resilience fallbacks). Primary-source lab language exists to borrow
   nearly verbatim.

---

## Q1 — Judge cadence: incremental vs batch

**Evidence for bounded review inputs (against one big batch pass):**
- LLM judgment accuracy degrades with input size: 75% at 64K → 61% at 262K
  tokens in a controlled study [arXiv:2510.05381, 2025, med]. Chroma's
  Context Rot (18 models, 2025-07-14) shows degradation "at every increment,
  not just near the limit," even on trivially simple tasks [primary,
  VERIFIED by direct fetch, high].
- Batch-prompting literature: concatenating many items per call is stable at
  small batch sizes, then "drastically degrades" as the concatenated prompt
  overwhelms reasoning [arXiv:2605.28268, med].
- Position bias in multi-item judging is real at scale (100K–150K instances,
  12–15 judges) and worsens with more items unless order-swapped and
  averaged — extra calls that erase the batch's savings [arXiv:2406.07791,
  high].
- Human code review (transferable): effectiveness falls off past ~200–400
  LOC per pass (SmartBear/Cisco, 2,500 reviews / 3.2M LOC) [med —
  primary PDFs didn't extract; consistent across secondaries]. A Google-
  attributed effectiveness curve exists but may conflate the two studies
  [low, DISPUTED — flagged].
- Compounding errors: verification deferred to the end lets a bad
  intermediate output enter downstream agents' context "as authoritative"
  [med, multiple sources]; SWE-Marathon (2026) documents monotonic pass-rate
  collapse with run length — claude-code scaffold 41.9%→3.2% as trials
  lengthen [arXiv:2606.07682, primary, high].

**Evidence against per-worker judge invocations (the other extreme):**
- Anthropic's own harness evolution REMOVED per-sprint evaluator gates when
  Opus 4.6 could hold coherence, replacing them with "a single pass at the
  end of the run," cutting cost $200 → $124.70 (solo baseline $9)
  [anthropic.com/engineering harness posts, primary, high]. Scaffolding
  should shrink as models improve — a per-lane judge is scaffolding beyond
  need when lanes share one frozen gate file and a slice is already
  PR-sized.
- Prompt-cache economics favor several small calls sharing a cached prefix
  over one giant call [med], but a mechanical post-flight (grep/diff/status
  by the orchestrator) costs near-zero versus a judge subagent — the cheap
  check belongs to the cheap mechanism.

**Conclusion (confidence: high on direction, med on thresholds):** current
design is correct: post-flight per lane (mechanical), one cold judge per
slice at integration, judge before the next slice builds on it. The
actionable refinement is a **slice-size discipline**: target judged diffs
≤~400 changed lines; a spec whose diff will exceed that should be split.
What would change this conclusion: a controlled study of incremental-vs-
batch verification in agent coding loops (none exists — flagged NOT FOUND
by two lanes independently).

## Q2 — Where adversarial spec review pays most

**Core evidence:**
- Cross-Context Review [arXiv:2603.12123, 2026-03, VERIFIED by direct fetch
  this session, high]: fresh-session review F1 28.6% vs same-session
  self-review 24.6% (p=0.008, d=0.52); **reviewing twice in the same session
  did NOT beat once** (21.7% — worse), isolating context separation, not
  repetition, as the active ingredient. Artifacts were code + technical
  documents (specs/plans transfer by analogy — one notch down).
- Intrinsic self-correction without external signal degrades reasoning
  performance [Huang et al., ICLR 2024, high]; tool-grounded critique helps
  (+7.7 F1, CRITIC) [high]. Implication: the grill must be GROUNDED — run
  the commands, check the paths — not a vibes critique.
- Real-world failure distribution [arXiv:2605.29442, 20,574 sessions,
  VERIFIED by direct fetch this session, high]: Misread Developer Intent
  26.95%, Inaccurate Self-Reporting 22.58% ("prematurely claim success" —
  the cold judge's exact target), Wrong Project Diagnosis 11.56% — of which
  **41% stem from Premature Action**: converging on a plausible
  interpretation without sufficient project context. That last number IS
  the first-time-unfamiliar-repo case.
- Classical baseline: Fagan-style pre-build inspection catches 80–90% of
  defects [med, secondary]. Boehm's early-is-cheaper curve is directionally
  right but its steepness is disputed [DISPUTED — Bossavit critique, med].
- Cost: closest proxy for a critique pass is ~2x tokens **of the reviewed
  artifact** [arXiv:2410.03663, med] — a spec is a few hundred lines;
  grilling it costs a rounding error against one builder lane.
- This repo's own history (primary, this session): two orchestrator spec
  defects shipped past PHASE 0 into frozen gates (repo-name grep collision;
  bookkeeping-commit enumeration) and cost a full judge round-trip each. A
  pre-freeze grill that mechanically executes gate commands would have
  caught the grep collision instantly.

**Conclusion (high):** add a **spec grill**: one cold, read-only subagent,
before freeze, given the draft gate file (which per current convention
already carries purpose + spec pointer + fix contract), tasked to falsify
it — execute each gate command against the current tree, verify referenced
paths exist, attack acceptance criteria for non-falsifiability, and flag
assumptions not evidenced in the repo. Default ON for the first slice in a
repo and for high-stakes slices; skippable for trivial slices
(scale-to-task). Post-build review remains the judge's job; PHASE 0 remains
the implementer's disagreement channel (it catches spec-vs-codebase
mismatches the grill's static+command pass may miss).

## Q3 — Teardowns: 11 systems (raw detail in `.architect/research/03-*`)

**Convergent findings that CONFIRM current design:**
- "Review by a separate agent is not redundant even with the same model" —
  independently arrived at by gpt-pilot [UNVERIFIED quote — primary fetch
  failed; med], Devin's write/catch/fix loop [high], Anthropic's retained
  evaluator [high], Factory.ai's dedicated skeptical validator role [high].
- "Verification defined before work": Factory.ai writes a validation
  contract of behavioral assertions before decomposing features [primary,
  high] — structurally identical to gates-freeze-before-dispatch.
- Discard-over-rescue: Ralph doctrine ("git reset --hard is easier") +
  HumanLayer retrospective [primary, high].
- Hard merge gates matter: the one independent Gas Town field report shows a
  worker **merging autonomously despite failing integration tests**; $100/60
  min; all 4 PRs closed as unusable [DoltHub 2026-01-15, independent,
  high]. Our judge-owns-merge rule is the direct countermeasure.
- Stateless orchestrator / stateful disk (firstmate "conversation memory is
  a cache") = our repo-is-memory [primary, high].

**Cheap additions worth adopting:**
1. **Repeated-identical-action stall detection** (OpenHands SDK: same
   action/args repeated = stuck; SWE-Marathon: the worst scaffold repeated
   32% of tool calls and produced 63/83 timeouts) — one line in the stall
   doctrine.
2. **Mechanical vs judgment review split** (Devin: bots own mechanical
   findings, humans own judgment calls) — codifies what post-flight vs
   judge already do; one clarifying line.
3. **Instruction-budget ceiling** (HumanLayer/RPI: models "silently skip"
   steps past ~150–200 system-prompt instructions [high, direct quote]) —
   a validator guard on total skill-text instruction count protects the
   Maintenance rule with a number.
4. Exponential-backoff idle supervision (firstmate, Gas Town patrols) —
   matches our heartbeat fallback; optionally name the backoff.

**Proved unnecessary elsewhere (validating our omissions):** tmux/keystroke
transports, external watcher daemons, dual approval authority, eager
scaffolding, per-sprint evaluator gates on strong models, fixed-interval
polling.

## Q4 — Lab practices with numbers

- Multi-agent economics: agents ≈4x chat tokens; multi-agent ≈15x; token
  spend explains 80% of performance variance (tokens+tools+model = 95%);
  "upgrading [the subagent model] is a larger performance gain than
  doubling the token budget" [Anthropic multi-agent post, primary, high].
  Implication: don't fan out by default (we don't); when a lane struggles,
  raising its model tier beats retrying with more tokens.
- **Dispute (unresolved, both positions primary):** Anthropic's 90.2%
  multi-agent gain is from a parallelizable research task; Cognition's
  "Don't Build Multi-Agents" argues single-agent + compression for coding
  because "sub-agents have no context of each other's work." Our design's
  answer: lanes with provably disjoint file sets + the repo as shared
  memory minimize exactly the shared-context need Cognition says breaks
  multi-agent coding. Most slices being 1 lane is already
  Cognition-compatible.
- Context: subagents should return condensed summaries (1–2K tokens)
  [Anthropic, primary]; no canonical compaction threshold exists in primary
  sources (secondaries disagree: 83.5/90/95%) [DISPUTED]; file-based memory
  beats conversation memory (84% token savings, 39% performance gain,
  Anthropic internal eval) [med — self-reported].
- Verification as progress signal: "agents prematurely claim success" is a
  top-3 real-world failure (22.58%) [arXiv:2605.29442, high]; Anthropic's
  feature-list harness ("unacceptable to remove or edit tests") is the same
  countermeasure class as our frozen gates [primary, high].
- NOT FOUND (three independent lanes): any study isolating cold-context
  judging as a variable; lab-published numeric circuit-breaker policy; a
  controlled re-dispatch-fresh vs iterate-in-context benchmark. Our
  positions on these rest on adjacent evidence + our own live canaries.

## Q5 — Ban silent fallbacks and unrequested backcompat shims: YES

- **Primary lab language exists** (OpenAI Codex Prompting Guide, fetched
  directly): "No broad catches or silent defaults: do not add broad
  try/catch blocks or success-shaped fallbacks; propagate or surface errors
  explicitly rather than swallowing them" and "No silent failures" [high].
- Anthropic ships NO equivalent in Claude Code's system prompt (verified
  absence) — the convention lives in user rules files, e.g. the CLAUDE.md
  in anthropics/claude-code#21027: "NEVER use fallback values - they hide
  errors and mask problems" [high]. So the ban belongs in OUR skill text —
  nobody upstream supplies it.
- Mechanism: fallback-laden code is likelier to pass whatever check scores
  the agent (Goedecke's RL-artifact hypothesis) [med] — in our loop, a
  silent fallback is a direct gate-gaming vector: TG-style gates measure
  output, and a fallback can fake the output while the primary path is
  broken.
- Backcompat shims: Fowler's YAGNI four-cost framework (build, delay,
  carry, repair) applies verbatim to unrequested compat code [med].
  Fail-fast doctrine (Shore, IEEE 2004) is the ancestor of every "assert
  loudly" rule found [med].
- Counter-evidence is scoped: resilience engineering endorses only
  *deliberately designed, explicit, visible* fallbacks for known external
  dependencies — no source anywhere argues agents should invent silent ones
  [high]. Hence the exception clause: fallbacks are allowed when the spec
  explicitly requests them.

## Proposed changes (for human approval — nothing built yet)

| # | Change | Cost | Evidence anchor |
|---|--------|------|-----------------|
| P1 | Builder block + architect-builder def: ban silent fallbacks / success-shaped defaults / unrequested backcompat shims; fail loudly; exception = explicitly-specced resilience | ~6 lines of text | Q5: Codex guide (primary), #21027, Goedecke, YAGNI |
| P2 | Pre-freeze **spec grill**: cold read-only subagent falsifies the draft gate file (runs commands, checks paths, attacks falsifiability); default ON for first-slice-in-repo + high-stakes, skippable for trivial | 1 subagent call/slice; ~2x spec tokens | Q2: CCR (verified), CRITIC, 2605.29442 41%-premature-action, our own 2 spec defects today |
| P3 | Slice-size discipline: target judged diffs ≤~400 changed lines; split specs that exceed it | 1 line in spec step | Q1: review-size evidence + context-rot |
| P4 | Stall doctrine: add repeated-identical-action/query detection | 1 line | Q3: OpenHands, SWE-Marathon 32%-duplication |
| P5 | Validator guard: instruction-budget ceiling on skill text (warn past ~150–200 imperative instructions total) | small check | Q3: RPI overflow (direct quote) |
| P6 | Alias-table note: when a lane fails once, prefer raising its model tier over re-running same-tier | 1 line | Q4: "upgrading model > doubling budget" (primary) |
| — | NOT adopting: per-lane judge calls, multi-slice batch reviews, external watchers, thread-preserving automations, vector-memory layers | — | Q1/Q3 evidence + simplicity mandate |

## Open questions (what would change conclusions)

- A controlled incremental-vs-batch verification benchmark for agent coding
  loops (nothing exists; P3's threshold is a transfer from human-review data).
- Cold-context judging isolated as a variable (CCR is closest; ours differs
  in that the judge also *executes* gates — stronger grounding, untested
  formally).
- gpt-pilot review quote: primary fetch failed; treat as corroborated-
  pattern, unverified-quote until fetched.
- Whether Cognition's anti-multi-agent position holds for disjoint-file-set
  lanes specifically (their argument assumes shared-context needs our lane
  contract removes by construction).

## Key citations (fetched this session or by a lane, dated, tiered)

- arXiv:2603.12123 Cross-Context Review [primary, 2026-03, verified]
- arXiv:2605.29442 20,574-session misalignment study [primary, 2026, verified]
- anthropic.com/engineering/multi-agent-research-system [primary, 2025]
- anthropic.com/engineering/effective-harnesses-for-long-running-agents + harness-design follow-up ($200→$124.70) [primary]
- trychroma.com/research/context-rot [primary, 2025-07-14]
- arXiv:2406.07791 position bias [primary, 2024]
- arXiv:2310.01798 LLMs cannot self-correct reasoning [primary, ICLR 2024]
- OpenAI Codex Prompting Guide (cookbook) fallback language [primary]
- dolthub.com/blog/2026-01-15-a-day-in-gas-town [independent field report]
- ghuntley.com/ralph + humanlayer.dev/blog/brief-history-of-ralph [primary/near-primary]
- factory.ai/news/missions-architecture [primary, vendor]
- arXiv:2606.07682 SWE-Marathon [primary, 2026]
- github.com/anthropics/claude-code/issues/21027 [primary practitioner evidence]
