# Is the docs/solutions/ lesson store worth keeping? The evidence

Research handoff, 2026-07-02 (r5 pass). Raw findings: `.architect/research/r5-*`
(gitignored). Question: does measured evidence support persistent
lesson/diagnosis files read back by future agent runs — the codify step
shipped in v5 (spec D9) — or is it unproven pattern-marketing?

## Answer first

**Keep it — the mechanism is one of the better-evidenced ideas in the
design — but the evidence draws three sharp boundaries, and we currently
violate one of them (no deletion policy).** The pattern that measurably
works is: *selective, distilled, operational* memory retrieved when
relevant. The pattern that measurably fails is: *accumulate-everything,
always-loaded, advice-shaped* context. docs/solutions/ as built sits on
the winning side of every measured split except pruning.

## What the evidence says

### Direct support (academic, measured, coding/computer-use agents)

- **SWE-Exp** [primary, 2025-07, abstract verified]: a "multi-faceted
  experience bank that captures both successful and failed repair
  attempts," distilled at multiple levels — structurally the closest
  published system to our Problem / What Didn't Work / Why This Works /
  Prevention schema. 73.0% Pass@1 on SWE-bench Verified (Claude 4 Sonnet);
  paper-body ablation: disabling experience extraction 42.0% → 36.0%
  (DeepSeek-V3).
- **Agent-KB** [primary, 2025-07]: cross-run experience knowledge base
  lifts SWE-bench Lite across agents and models — OpenHands+Claude-3.7
  30.0% → 46.7% pass@1 (max-iter 50).
- **Agent S** [primary, 2024-10]: *distilled summaries beat raw
  trajectories* — OSWorld ablation subset 26.15% with summarized experience
  vs 18.46% storing full trajectories. Validates the short-diagnosis-file
  format over log dumps.
- **ExpeL** [primary, 2023/AAAI-24]: distilled natural-language insights
  transfer across tasks (+7pp on FEVER transfer); hand-crafted insights
  alone also helped (+4pp over ReAct).
- **Memory management ablations** [primary, 2025-05, arXiv 2505.16067]:
  the decisive split — "add all" memory was WORSE than a fixed memory on
  2 of 3 agent tasks; **selective addition beat naive growth by ~10%
  absolute on average**, and deletion helped further (EHRAgent: 42.88 acc
  with 248 curated memories vs 38.89 with 1,012 accumulated ones).
  Mechanism named "experience-following": agents imitate retrieved
  records, so bad/stale records propagate errors.

### Direct caution (measured)

- **"Evaluating AGENTS.md"** [primary, 2026-02, abstract verified]:
  always-loaded repository context files "do not generally improve task
  success rates, while increasing inference cost by over 20%";
  LLM-generated files hurt in 5 of 8 settings; human-written ones averaged
  only +2.4%. The paper's own carve-out is exactly our category: "context
  files are useful for specifying **non-standard coding practices**" — i.e.
  missing information the agent cannot derive from the repo. Harm was
  behavioral (agents dutifully obeying extra directives), with NO
  correlation to file length — there is no known safe size threshold.
- **Irrelevant-context degradation** [primary, 2023-2025]: adding
  distractor content measurably wrecks reasoning (e.g. GPT-4.1 26% → 2%
  as distractors scale; 30K tokens of masked filler alone dropped Llama3
  HumanEval 57.3% → 7.3%).
- **Persistent writable memory is an attack surface** [primary, 2024-25]:
  AgentPoison ≥80% attack success at <0.1% poison rate; MINJA >95%
  injection success — memory an agent writes becomes a delayed
  prompt-injection channel.
- **Practitioner systems: zero published measurements** (NOT FOUND for
  compound-engineering, CLAUDE.md memory, Cursor rules, gstack learnings —
  a 401-repo Cursor-rules study says impact "remains an open question").
  Indirect signal: every mature system grew pruning machinery (gstack
  confidence-decay + STALE/CONFLICT checks; Claude docs cap memory loading
  and warn adherence drops past ~200 lines) — evidence the failure mode is
  real enough that everyone built defenses.

## Scorecard for docs/solutions/ as built

| Evidence-backed rule | Our state |
|---|---|
| Selective addition (nontrivial only) | ✓ codified bar: "would it save 5+ min / recur?" |
| Distilled schema incl. failed attempts | ✓ Problem / What Didn't Work / Why / Prevention |
| Missing-information content (env quirks, sandbox behavior) not derivable from repo | ✓ all 4 entries are this class |
| Not always-loaded into every agent | ✓ brain reads at grounding; lanes get only relevant bits via spawn context |
| Facts + prevention, not directives/style advice | ✓ today — the drift risk to police |
| Provenance + review (orchestrator-written, in git, PR-visible) | ✓ mitigates the injection surface |
| **Deletion/expiry policy** | **✗ missing — the strongest ablated mitigation we lack** |

## Recommendation

1. **Keep docs/solutions/.** The mechanism has better measured support
   than most of the v5 design's inputs.
2. **Add the pruning rule** (one paragraph in the codify convention):
   entries carry dates; at grounding, an entry whose referenced paths,
   tools, or environment facts no longer hold is flagged stale and deleted
   in the next docs lane (git history preserves it). Target steady state:
   a handful of live entries, never an archive.
3. **Hold the content line**: solutions record operational facts and
   preventions, never general advice, style rules, or repo overviews —
   the measured-harm categories.

## Key citations

- SWE-Exp [primary, 2025-07] — https://arxiv.org/abs/2507.23361
- Agent-KB [primary, 2025-07] — https://arxiv.org/pdf/2507.06229
- Agent S [primary, 2024-10] — https://arxiv.org/html/2410.08164v1
- ExpeL [primary, AAAI-24] — https://arxiv.org/html/2308.10144v2
- Memory-management ablations [primary, 2025-05] — https://arxiv.org/html/2505.16067v1
- Evaluating AGENTS.md [primary, 2026-02] — https://arxiv.org/abs/2602.11988
- Irrelevant context [primary, 2023/2025] — https://ar5iv.labs.arxiv.org/html/2302.00093 ; https://arxiv.org/html/2505.18761v2 ; https://arxiv.org/html/2510.05381v1
- AgentPoison / MINJA [primary, 2024-25] — https://billchan226.github.io/AgentPoison.html ; https://arxiv.org/html/2503.03704v1
- SkillsBench (+16.2pp curated skills; 16/84 negative) [primary, 2026] — https://arxiv.org/html/2602.12670v1
- Claude Code memory docs (200-line adherence caveat) [primary] — https://code.claude.com/docs/en/memory
