# DESIGN — The Architect Loop v2

**A source-backed design for a Claude Code harness skill in which Claude Fable 5
(high effort) acts as architect/orchestrator and GPT-5.5 via Codex CLI (xhigh
reasoning) acts as builder, with the repo as the only memory.**

Researched June 2026 from Anthropic engineering posts, the official Fable 5 and
Codex CLI documentation, and widely used community harness skills. Prescriptive
claims below cite their sources. This document is the "why"; the skill files in
`skills/architect/` are the "how".

Sections 1–11 are the historical evidence trail (v2 → v4 eras); §12 describes
the current v5 system. Historical sections cite run artifacts that were later
cleaned from the working tree (`docs/HANDOFF.md`, per-run `docs/gates/` and
`docs/lanes/` files, superseded specs) — those anchors resolve in git history,
not on disk.

---

## 1. The problem this design solves

Single-agent coding sessions degrade in three predictable ways:

1. **Context rot** — performance falls as the window fills; Anthropic calls the
   context window "a finite attention budget with diminishing returns"
   ([Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)),
   and practitioners report a "dumb zone" past ~40% utilization
   ([HumanLayer ACE-FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents)).
2. **Self-grading** — the agent that wrote the code reports its own success.
   Benchmark studies found 47–74% of self-improvement runs showed proxy gains
   without real gains, with agents escalating from overt to obfuscated reward
   hacks ([OpenReview](https://openreview.net/forum?id=ikrQWGgxYg),
   [arXiv:2503.11926](https://arxiv.org/pdf/2503.11926)).
3. **Goalpost drift** — acceptance criteria written (or edited) after results
   exist always pass.

The sources surveyed point to the same basic shape — Anthropic's
[harness design post](https://www.anthropic.com/engineering/harness-design-long-running-apps),
obra/superpowers' subagent-driven development, the Ralph loop, and GitHub Spec
Kit:

> **Separate planning context from execution context. Persist state in the repo,
> not the conversation. Dispatch fresh-context workers per task. Verify with an
> agent that didn't write the code.**

This loop adds one more separation on top: **cross-vendor judgment**. The builder
and the judge are different models from different labs, which reduces
same-model review bias ([OpenAI's own pitch for the Codex↔Claude
bridge](https://www.mindstudio.ai/blog/openai-codex-plugin-claude-code-cross-provider-review)).
The split also lines up with available benchmark claims: GPT-5.5 leads
Terminal-Bench 2.0 (82.7%) for hands-on terminal work, while Anthropic positions
Fable 5 for long-horizon judgment and persistent file-based memory
([Fable 5 announcement](https://www.anthropic.com/news/claude-fable-5-mythos-5)).

The economics are another reason for the split: judgment minutes on the expensive
model, typing hours on the flat-rate one. Community measurements of
orchestrator/worker splits report 58–74% lower cost versus running the top model
end-to-end
([Fable 5 Orchestrator Playbook](https://www.developersdigest.tech/blog/fable-5-orchestrator-model-playbook)).

---

## 2. Roles

| Role | Who | Effort | Owns |
|---|---|---|---|
| **Architect** | Claude Fable 5 in Claude Code (`effort: high` via skill frontmatter) | minutes per work block | arbitration, judging raw evidence against frozen gates, next-slice specs, kill/continue calls |
| **Builder** | GPT-5.5 via `codex exec` (`model_reasoning_effort: xhigh` default; architect may dial per slice) | hours per slice | implementation, lane agents, raw-results reporting |
| **Memory** | the repo: `docs/HANDOFF.md`, `docs/gates/`, git history | permanent | everything; not in the repo = didn't happen |
| **Human** | you | final | scope, irreversible calls, taste |

Why `high` for the architect: Fable 5's docs recommend `high` as the default and
`xhigh` for capability-sensitive work; low effort on Fable 5 already exceeds
xhigh on prior models ([Prompting Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)).
Judgment over a small handoff file is squarely in `high` territory; the skill
pins it with the `effort:` frontmatter key so it doesn't depend on session
settings.

Why `xhigh` for the builder: OpenAI's GPT-5.5 evals ran at xhigh, and independent
effort-curve data shows xhigh winning on the metrics that matter for unattended
work — semantic equivalence to the human PR (88% vs 69% at high) and
review-pass rate (69% vs 38%) — at ~2.2× the cost of high
([stet.sh effort curve](https://www.stet.sh/blog/gpt-55-codex-graphql-reasoning-curve)).
Since the builder runs unattended for hours, review-survival is the metric to
buy. The architect downgrades to `high` for routine, well-specified slices where
the data shows high is equal on test-pass — this is a per-slice judgment call
the spec records explicitly.

Codex `workspace-write` is the only builder backend with verified sandbox
`.git` write protection; that guarantee is specific to Codex under
workspace-write, not a general property of every harness. Claude builders use
permission-deny rules plus a post-flight branch and commit check instead
(F8/F12/F13; developers.openai.com/codex/agent-approvals-security,
code.claude.com/docs/en/headless).

## Model roles

The loop now treats **brain** and **brawn** as configurable roles, not fixed
brand names. Brain is the judgment session the human launched or the loop driver
starts; brawn is the unattended builder CLI/model selected for lane execution.
The skill detects the harness and advises, but it does not self-switch the brain
mid-session because no supported harness exposes a reliable live model signal to
subprocesses (F6; code.claude.com/docs/en/cli-reference).

Zero-config defaults optimize for one installed subscription and low setup:
brain inherits the current session, and brawn defaults to the same family one
step down. That mirrors the `opusplan` precedent and other inherit-by-default
systems while avoiding a config matrix: Claude Code brain routes to
`claude/sonnet`; Codex brain routes to `gpt-5.5` at `high` effort. The trade is
explicit: builder hours concentrate on the same subscription as judgment, and
brain and brawn share a model family unless the user opts out (F9; aider issues
#3087/#3085/#3287/#3543, block/goose#4036, Claude Code `opusplan` docs).

Cross-family diversity is spent first at the review gate, not the build default.
Same-family judge bias is measured at the model-family level, with mitigation
coming from a cross-family judge or ensemble; this design uses the other
supported CLI for high-stakes review when it is on PATH, and otherwise logs the
same-family caveat instead of blocking work (F10; arXiv:2410.21819,
NeurIPS 2024 SafeGenAI, Panickssery et al. 2024).

Configuration is one flat two-key file: `brain = <cli>/<model-spec>[:<effort>]`
and `brawn = <cli>/<model-spec>[:<effort>]`. Repo `.architect/config` wins over
user `~/.architect/config`; unknown keys warn. A configured but unavailable
brawn degrades to the tier-down default with a requested-vs-substituted warning,
and an unavailable cross-family reviewer degrades to a fresh same-CLI review
with the F10 caveat. The single alias table is the owned rot point: it maps
`codex/best`, `claude/best`, `codex/tier-down`, and `claude/tier-down` to
current CLI flags, so model churn is reviewed in one place rather than scattered
through specs (F9/F11; superpowers audit-trail precedent).

Cross-vendor model mixing is documented as asymmetric. Claude Code can point at
Anthropic-compatible gateways via `ANTHROPIC_BASE_URL` and
`ANTHROPIC_AUTH_TOKEN`; z.ai documents a GLM endpoint for Claude Code, but the
specific GLM 5.2 recipe remains unverified here and Anthropic does not bless
non-Claude routing. Codex accepts Responses-API providers, so raw Anthropic or
chat-completions endpoints need a translating gateway (F7; docs.z.ai,
Anthropic gateway docs).

---

## 3. The twelve design rules

Each rule below is enforced mechanically by the skill, not left as advice.

### R1. Repo docs are the memory; not in `HANDOFF.md` = didn't happen
Anthropic's long-running-agent harnesses use a progress file + git history as
the cross-session memory and find "compaction alone is insufficient — structural
artifacts are the load-bearing memory"
([Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).
The architect refuses to judge results that exist only in chat output.
Community handoff conventions apply: the next session must grok the handoff in
under a minute; TL;DR first; exact paths/commands over prose
([handoff-memory conventions](https://lobehub.com/skills/neversight-learn-skills.dev-handoff-memory)).

### R2. Gates freeze before results exist, and live where the builder can't move them
Anthropic's three-agent harness has the generator and evaluator "negotiate a
sprint contract" in shared files **before coding**, then freeze it
([Harness Design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
The reward-hacking literature adds the mechanical requirement: keep graders and
criteria out of the agent's editable blast radius. Implementation: gates are
written to `docs/gates/<slice>.md` before dispatch, committed, and the
architect's post-run verification step includes `git diff` on `docs/gates/` —
**any builder edit to a gate file is an automatic slice FAIL**, regardless of
results. Criteria are quoted verbatim when judging, never restated from memory.

### R3. The builder never grades its own work — and neither does the architect alone
Two-stage review, fresh contexts, is the most-replicated community pattern
(superpowers' spec-compliance review then quality review;
[superpowers](https://github.com/obra/superpowers)). Anthropic's Fable 5 guide
states it directly: "Separate, fresh-context verifier subagents tend to
outperform self-critique." The loop's review stack:
1. Builder's own reviewer lane (inside Codex, never writes feature code) — cheap first pass.
2. Architect runs the gates **itself** and reads the output — "subagent test
   claims are hearsay" (your `/orchestrator` rule, matching Anthropic's
   "demand evidence, not assertions").
3. Cross-model adversarial pass for high-stakes slices: `codex review --base
   <branch>` (GPT reviewing its own lane output against the spec is still a
   different context; or a fresh Claude subagent red-teams the diff). Calibrate
   the reviewer: *"flag only correctness/requirement/invariant gaps with
   file:line evidence — no style preferences"* — an uncalibrated reviewer
   always finds something and that spirals into gold-plating.

### R4. Grade the outcome, not the path
From Anthropic's evals guidance: rigid step-sequence grading is brittle; judge
each gate as an independent dimension; give the judge an "unknown/INVALID"
escape so unmeasured ≠ passed
([Demystifying Evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)).
Verdicts are per-gate: **PASS / FAIL / INVALID** (INVALID = not measured the way
the gate specifies), then a slice-level **kill / continue** call.

### R5. Disagreement is mandatory, with citations
The builder's PHASE 0 must surface every disagreement with the spec, citing real
files; silent compliance is a defect the architect flags. This is the loop's
defense against spec errors compounding — and it matches GPT-5.5's profile:
prescriptive specs are followed literally, so the only place errors get caught
is before execution. Every open disagreement gets an explicit
**ACCEPT / REJECT / MODIFY + one line why**. No deferrals.

### R6. Delegation carries the full contract: objective, output format, tool guidance, boundaries
Anthropic's multi-agent research system found vague delegation causes
duplication and misinterpretation; every dispatch needs those four parts
([Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)).
The slice spec is exactly those four parts plus the frozen gates. Specs are
self-contained — the builder gets everything in the dispatch block, with repo
paths to read for detail (just-in-time retrieval, not context-stuffing). Per
OpenAI's prompting guidance, the full task spec goes up front in one
well-specified turn — ambiguous progressive specification degrades both token
efficiency and performance.

### R7. One slice per loop iteration; fresh builder context per slice
The Ralph loop's core lesson — and its author's explicit warning about
skill-ifying it: "if you implement Ralph as a skill inside the harness, you're
missing the point — the point is the always-fresh context"
([ghuntley.com/ralph](https://ghuntley.com/ralph/),
[HumanLayer's history](https://www.humanlayer.dev/blog/brief-history-of-ralph)).
This skill respects that: the architect's context holds judgment only; every
slice is a **fresh `codex exec` process**. `codex exec resume --last` is used
only for follow-ups within the same slice (answering the builder's PHASE 0
questions), never to stretch one builder context across slices. "Code is cheap":
when a long run leaves the repo broken, `git reset` and re-dispatch beats rescue
prompting.

### R8. Parallelism is architect-orchestrated: one worktree + one fresh `codex exec` per lane, capped at 4
Merge conflicts between parallel agents are the top reported multi-agent failure;
the converged mitigation is mapping file-touch sets before parallelizing, one
git worktree per agent, and a practical ceiling of 2–4 lanes before coordination
overhead dominates ([Intility engineering](https://engineering.intility.com/article/agent-teams-or-how-i-learned-to-stop-worrying-about-merge-conflicts-and-love-git-worktrees),
[MindStudio worktrees](https://www.mindstudio.ai/blog/git-worktrees-parallel-ai-coding-agents)).
**The architect — not Codex — owns the fan-out.** The spec splits the slice
into 1–4 lanes whose file sets are checked for overlap; each lane is an isolated
worktree running its own `codex exec` process, writing its own lane report
(`docs/lanes/`); the architect runs per-lane boundary checks (`git status`
must show only declared files), commits each passing lane, and merges
sequentially with gate smoke-runs after every merge. This replaced an earlier
design that delegated lane-spawning to Codex's internal multi-agent feature —
which is opt-in (`[features] multi_agent`, off by default) and silently
degrades to serial work when unset, with zero architect visibility either
way. Architect-owned worktrees make a merge conflict a detectable spec defect
instead of a silent hazard, and isolate per-lane failure (discard one lane,
not the slice).

### R9. Supervise asynchronously; never block on the builder
Fable 5 is specifically tuned for this: "significantly more dependable at
dispatching and sustaining parallel subagents… prefer async communication over
blocking on each return" ([Prompting Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)).
The dispatch runs `codex exec` in the background; the architect ends its turn or
does other judgment work, then runs the post-flight checks when the run
completes. Multi-hour builder runs are normal (community reports: 6.5h runs at
~20% of a weekly Codex quota).

### R10. Grounded progress claims — audit every status against tool output
Fable 5 guidance: instruct the model to audit every status claim against a tool
result from the session before reporting; in Anthropic's testing this "nearly
eliminated fabricated status reports." Applied twice here: the architect's own
reports, and the handoff rules for the builder (raw tables/numbers/SHAs only —
"no interpretation, no 'promising'; verdicts belong to the architect and the
human").

### R11. Ground before judging; scale effort to the task
Carried over from your `/orchestrator` skill, and matching Claude Code best
practices: read the project's own operating docs (CLAUDE.md/AGENTS.md → README →
architecture docs) and learn its verification gate before any judgment; a wrong
assumption multiplies through every dispatch. And not everything needs the loop:
trivial work gets done directly; the full pipeline is for slice-sized work and
up. "Every component in a harness encodes an assumption about what the model
can't do on its own" — don't run a $200 harness on a $9 task
([Harness Design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).

### R12. Keep the skill thin, declarative, and prunable
Two reasons. (a) Claude Code skill mechanics: only descriptions sit in context
until invoked, but the body stays in context for the session — keep it terse,
push detail to referenced files ([Skills docs](https://code.claude.com/docs/en/skills)).
(b) Obsolescence: "skills developed for prior models are often too prescriptive
for Claude Fable 5 and can degrade output quality" (Fable 5 guide), and the
Claude Code team's own position is that scaffolds get obsoleted by better models
([Latent Space, harness engineering](https://www.latent.space/p/harness-eng)).
The skill states *invariants* (the rules above) and *interfaces* (the dispatch
contract), not step-by-step micro-procedures. Review it against each new model
generation and delete what the model now does unprompted.

---

## 4. The builder interface (verified against Codex CLI ≥ 0.133, June 2026)

Facts the skill encodes — several correct widespread misinformation:

- **Model slug is `gpt-5.5`**, not `gpt-5.5-codex`; the `-codex`-suffixed line
  ended at gpt-5.3 and is deprecated under ChatGPT sign-in. Pin it explicitly —
  automations have been reported silently defaulting to older models.
- **`codex exec` is non-interactive by design** — `-a/--ask-for-approval` and
  `--search` are TUI-only flags that exec rejects (verified live on 0.139).
  The sandbox flag is the only permission control. Web search is on by
  default in current Codex; `-c web_search="live"` forces fresh results
  (older CLIs: `--enable web_search`, then `-c tools.web_search=true`).
  `--full-auto` is deprecated. These flags churned three times in 2026 alone —
  hence the skills' one-canary-before-fan-out rule per environment.
- **Effort** is `-c model_reasoning_effort="xhigh"` (or `high`), per invocation.
- **Structured telemetry**: `--json` (JSONL event stream) and
  `-o <file>` / `--output-last-message` for the final message;
  `--output-schema <schema.json>` can force the builder's final report to
  conform to a JSON schema — used for the machine-checkable run report.
- **Session continuity**: `codex exec resume --last "<follow-up>"` for
  same-slice follow-ups.
- **Goal Mode** (`/goal`) is interactive-TUI; GA and default since v0.133.0
  (May 2026). Real subcommands: bare `/goal`, `/goal pause|resume|clear`. For
  headless dispatch, `codex exec` already loops until done — Goal Mode is the
  manual-mode equivalent when you babysit a run yourself.
- **`AGENTS.md`** is the builder's standing context (concatenated root-down,
  deeper files override). The loop's PHASE rules live in the dispatch block, not
  AGENTS.md, so they version with the skill; repo-specific build/test commands
  belong in AGENTS.md per OpenAI's guidance.
- **`codex review --base <branch>`** gives an independent reviewer context for
  the cross-model review gate.

Canonical dispatch:

```bash
codex exec -C <repo> --sandbox workspace-write \
  -m gpt-5.5 -c model_reasoning_effort="xhigh" \
  --json -o .architect/last-run.md \
  "<builder block: PHASE rules + slice spec + frozen gate references>"
```

Subscription note: ChatGPT-plan quotas are per-5-hour window plus a weekly cap;
long runs draw on the weekly pool. For unattended overnight loops that must not
die mid-run, `CODEX_API_KEY` per-token billing avoids window exhaustion — the
architect notes this trade-off but defaults to the subscription.

---

## 5. The loop, end to end

```
┌──────────────────────────── one work block ────────────────────────────────┐
│                                                                            │
│  /architect                                                                │
│   0. Ground: CLAUDE.md/AGENTS.md → verification gate → docs/HANDOFF.md     │
│   1. Arbitrate: every open disagreement → ACCEPT/REJECT/MODIFY + why       │
│   2. Judge: run gates yourself; verdict per gate vs verbatim frozen text   │
│      PASS / FAIL / INVALID → kill / continue                               │
│   3. Spec next slice: objective + output format + tool guidance +          │
│      boundaries + out-of-scope; freeze gates to docs/gates/<slice>.md;     │
│      commit the freeze                                                     │
│   4. Dispatch: 1-4 parallel codex exec lanes, one git worktree each        │
│      (background, fresh context, xhigh default). Per lane: PHASE 0         │
│      disagree-or-fail → PHASE 1 contracts frozen → PHASE 2 build own       │
│      files only → raw lane report (docs/lanes/), no commits                │
│   5. Post-flight per lane: raw-only? disagreements raised? gates           │
│      untouched? in-bounds? → architect commits + merges lanes with         │
│      gate smoke-runs; verdict waits for next block                         │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
         repo carries everything across the gap between blocks
```

The human reads the handoff between blocks and overrides anything. Architect
verdicts on a slice always happen in a **later** architect session than the one
that dispatched it — the dispatcher never grades the run it launched in the same
breath (fresh-context judgment, R3).

### Optional pre-spec research fan-out

Between judging and speccing, the architect may run a research phase: 3–5
parallel `codex exec --sandbox read-only -c web_search="live"` researchers, each
answering one narrow non-overlapping question, with the architect adversarially
verifying load-bearing claims and writing `docs/spec/<slice>.md` itself. Design
decisions behind it:

- **Trigger-gated, not always-on.** "Research if you think it helps" either
  fires constantly or never; instead the skill names three concrete triggers
  (slice depends on external APIs/libraries/versions new to the repo; a
  technology choice needs facts nobody has; the human asks) and defaults to
  skip — the builder's verify-against-reality requirement already covers
  routine API checks (R11: scale effort to the task).
- **Progressive disclosure.** The mechanics live in `research.md`, read only
  when a trigger fires — the default architect context never pays for them
  (R12, per [Skills docs](https://code.claude.com/docs/en/skills) guidance to
  push detail to referenced files).
- **Codex researchers, Fable judgment.** Research is coverage work — it runs
  at `high` effort on the flat-rate OpenAI sub, read-only sandboxed with live
  search ([CLI features](https://developers.openai.com/codex/cli/features);
  `[tools.web_search] allowed_domains` available as prompt-injection defence).
  Verification of load-bearing claims and PRD authorship stay with the
  architect — researchers are explicitly forbidden from making
  recommendations, the research-side equivalent of "raw results only" (R3).
- **Findings discipline** mirrors deep-research harnesses: every finding
  carries a URL, date, exact quote/figure, and confidence tag; disagreements
  between sources are reported, not resolved; "NOT FOUND" beats inference.
  Multi-angle decomposition (docs / changelogs / failure reports /
  alternatives) follows the multi-modal-sweep pattern from
  [Anthropic's multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system).
- **The spec is repo memory; raw findings are not.** `docs/spec/<slice>.md` is
  committed with citations (R1); raw researcher output stays in the gitignored
  `.architect/research/`. The builder's PHASE 0 challenges the spec like any
  other spec input.

### Two skills: `/architect` and `/architect-research`

Discovery-scale research (brainstorming, technology selection, SOTA surveys)
is a **separate skill**, not a mode of the loop. Three reasons: different
invocation pattern (discovery precedes a project; the loop runs per work
block), different deliverable (a decision report vs a dispatch), and cost —
research-grade fan-out runs ~15× chat-level tokens
([Anthropic multi-agent research](https://www.anthropic.com/engineering/multi-agent-research-system)),
so it must be deliberately invoked, never a side-effect. The loop's step 3
routes: discovery scale → `/architect-research`; narrow slice facts → the
inline fan-out above.

`/architect-research` encodes the methodology found across the surveyed
deep-research systems. As of v2.3 the decomposition is **scout-first and
topic-designed, not a fixed lane taxonomy** — a 2026-06 evidence review found
all five production deep-research systems (OpenAI DR, Anthropic, Gemini,
Perplexity, Kimi) use adaptive planner-driven decomposition and none uses
fixed lanes; 4/5 leading OSS frameworks generate the decomposition with an
LLM; and dynamic beats static decomposition on GAIA
([OAgents](https://arxiv.org/abs/2506.15741): 47.88 static → 51.52 dynamic;
[AOrchestra](https://arxiv.org/abs/2602.03786): on-demand subagent
construction +16.28% relative). The six source-class sections in `lanes.md`
became a tactics library the orchestrator draws from when designing lanes:

- **Scout → design → fan out.** For brainstorm-scale questions, one cheap
  codex scout (~10 searches) maps terminology, load-bearing
  systems, named people, and the topic's natural fault lines; the architect
  then designs 3–6 topic-specific lanes from that map. Source-derived
  perspective discovery was STORM's largest measured lever (unique references
  99.83 vs 54.36 without it); Anthropic's lead agent and OpenAI/Gemini's
  user-visible research plans are the production analogs. Comparisons and
  fact-finds skip the scout — recon that tells you nothing is pure latency.
- **Effort scaling embedded in the prompt** — 1 researcher for fact-finds,
  2–4 for comparisons, 4–6 designed lanes for surveys; search budgets 5/15/25
  by tier; ≤5 subjects per researcher (context-exhaustion guard — a
  researcher that fills its window dies without writing output; bisect dead
  lanes); saturation stop (two no-new-fact searches); max 2 gap-fill rounds.
  Scaling numbers from Anthropic's published orchestrator heuristics —
  without them, leads over- or under-delegate.
- **Perspective-diverse decomposition, overlap-checked** before dispatch
  (Stanford [STORM](https://arxiv.org/abs/2402.14207)'s
  perspective-guided questioning; the direct antidote to query collapse).
- **Scope → brief → plan-before-burn** (LangChain
  [Open Deep Research](https://github.com/langchain-ai/open_deep_research)'s
  brief-as-north-star; Gemini's user-visible plan). The brief is restated in
  the report so scope drift is auditable.
- **Verification as a separate pass against raw sources**: ≥2
  independent-origin sources per load-bearing claim; four-state tags
  (VERIFIED/UNVERIFIED/DISPUTED/SUSPICIOUS); adversarial falsification
  searches; **citations only from URLs fetched this session** — even
  search-grounded agents fabricate
  [3–13% of URLs](https://arxiv.org/pdf/2604.03173); recency discipline
  (dated claims, date-restricted queries) because retrieval systematically
  favors stale sources.
- **Parallelize gathering, never synthesis** — one author writes the whole
  report (LangChain's section-parallel writer produced disjoint reports;
  Anthropic's CitationAgent exists to stop summarizing-of-summaries).
  Output is decision-oriented: answer-first, per-finding "what would change
  this conclusion", explicit open questions.
- **Expert opinion as a second-wave lane with its own evidence class.** You
  can't track experts until you know who they are, so lane 6 dispatches in
  the gap round, roster-seeded by the first wave (survey authors, top-repo
  maintainers, recurring names). Platform reality is encoded: experts' blogs
  and HN's keyless Algolia author search are the reliable channels; X is
  login-walled for agents (use `site:x.com` indexed search + profile URLs,
  not third-party viewers), and Bluesky's public search API has returned 403
  since March 2025 ([bsky-docs#332](https://github.com/bluesky-social/bsky-docs/issues/332)).
  Opinions are reported as dated, conflict-of-interest-flagged positions and
  never count toward the ≥2-source rule — but expert *disagreements* are
  first-class findings, since they locate the genuinely open questions.
- **Verified source-class endpoints** live in `lanes.md`: arXiv API recency queries,
  Semantic Scholar citation snowballing (the most reliable "latest papers"
  method), deps.dev/ecosyste.ms dependents (adoption evidence beats stars —
  ~4.5M [fake stars](https://arxiv.org/abs/2412.13459) documented), the
  emerging-vs-hype conjunction gate, the production-grade gate + four-category
  pattern-mining procedure, HN Algolia. Papers With Code is dead (July 2025;
  HF Papers succeeded it) — a stale-source trap the lane file flags.

---

## 6. Failure modes → mechanical mitigations

| Failure mode | Mitigation in this design |
|---|---|
| Reward hacking / gate tampering | Gates committed pre-dispatch in `docs/gates/`; post-flight `git diff` check; tampering = automatic FAIL (R2) |
| Builder grades own work | Raw-results-only handoff; architect runs gates itself; cross-model review (R3, R10) |
| Goalpost moving | Verbatim gate quoting; gates never edited after results; missing gate = spec defect, frozen for next slice only (R2, R4) |
| Scope creep | Explicit out-of-scope list per slice; silent scope additions = builder failure; architect flags creep by name (R5, R6) |
| Context rot | Architect context holds judgment only; fresh builder process per slice; repo is the memory (R1, R7) |
| Merge conflicts between lanes | Disjoint-file-set lanes, ≤3–4, worktrees, one reviewer lane gating merges (R8) |
| Placeholder implementations | Gate commands are end-to-end and executable; "search before implementing; no placeholder code" in the builder block (R4) |
| Broken repo after a long run | One slice per iteration; commit per lane; `git reset` + re-dispatch over rescue prompting (R7) |
| Fabricated status reports | Every status claim audited against a tool result, both sides (R10) |
| Builder self-misidentification | Lane identity clause tells Claude Code lanes their redirected event stream is their own and whether they are the only builder; prevents a lane from reading its own stream, inferring a duplicate worker, and aborting with zero artifacts (2026-07-02 live loop canary, this repo) |
| Gate-passing but unmergeable work | Judge reads the diff against spec intent, not gate output alone — METR: 38% test-pass, 0 mergeable as-is; cross-model review for high-stakes (R3, R4) |
| Builder gaming visible gates | Gates frozen + read-only; architect-run verification; no builder iterate-against-gate feedback loops (ImpossibleBench: visible-test loops raised cheating 33%→38%) (R2, R3) |
| Stalled unattended runs | The driver WAIT cycle schedules liveness by construction: if lanes are still in flight, the next loop iteration runs the fast path, checks event-file growth, and applies the rescue ladder. The root cause chain it prevents is out-of-workspace temp/cache paths (`C:\tmp`), parallel gate execution, missing timeout ceilings, and no scheduled return (Part A; `docs/spec/v3-loop-stall-prevention.md`). |
| Runaway loop | Fail-safe sentinel parsing treats missing, unparseable, or untouched `LOOP:` state as STOP; `--max-iters` defaults to 50, optional `--max-hours` bounds wall time, the circuit breaker stops after 3 no-progress iterations or 5 nonzero exits, and `docs/STOP` is checked before every invocation (F5; docs/gates/v3-loop.md C1/C4). |
| Researcher context exhaustion | ≤5 subjects per lane; hard context rules in the preamble; bisect-and-redispatch dead lanes (lanes.md) |
| Harness bloat / obsolescence | Thin declarative skill; per-model-generation pruning review (R12) |

---

## 7. What this deliberately is not

- **Not context reuse disguised as automation.** Loop mode is an outer driver
  that starts a fresh one-shot agent session per iteration because in-harness
  self-continuation is the documented anti-pattern: Ralph-style same-session
  loops accumulate context into the "dumb zone," and Claude Code `/loop`,
  `--continue`, `--resume`, and `--fork-session` all reuse conversation context
  (F1/F2; aihero.dev/why-the-anthropic-ralph-plugin-sucks, ghuntley.com/ralph,
  humanlayer.dev/blog/brief-history-of-ralph,
  code.claude.com/docs/en/cli-reference).
- **Not a GUI-terminal spawner.** The productized loop keeps one persistent
  visible surface: the driver's terminal plus logs. Spawning new visible
  terminals from inside agent sandboxes is the highest-friction path across
  Windows, macOS, and headless Linux; detached process plus logfile is the
  reliable primitive (F3; developers.openai.com/codex/concepts/sandboxing,
  codex.danielvaughan.com Windows sandbox analysis).
- **Not a general-purpose orchestrator.** Your `/orchestrator` skill covers
  single-model plan→delegate→review inside Claude Code. This skill is the
  cross-vendor loop; it imports `/orchestrator`'s grounding, delegation-contract,
  and verify-it-yourself rules rather than duplicating the whole pipeline.
- **Not an autonomous infinite loop.** The human sits between work blocks by
  design — that's where kill/continue authority lives. If you want unattended
  multi-block runs, loop mode is the productized extension: it keeps a single
  driver terminal visible, starts fresh one-shot sessions, and reads `LOOP:`
  sentinels between iterations. It is still not the default (and note `claude -p` draws on
  normal subscription quota while the June 2026 Agent SDK credits split is
  paused; recheck support.claude.com/en/articles/15036540 before relying on a
  different billing split, F4d).
  The autonomy trade is explicit: loop mode removes the human from between
  blocks, so arbitration defaults to the architect unless the spec marks a
  decision human-only; `LOOP: STOP` is the guard for completion, hard-rule
  stops, and human-only arbitration (F4/F5; code.claude.com/docs/en/agent-view,
  code.claude.com/docs/en/headless, PRD section 6).
- **Not just Goal Mode.** Codex's Goal Mode already loops
  plan→act→test→review against a stopping condition. This design adds extra
  separation around Goal Mode: cross-model judgment, frozen external
  gates, arbitration, and repo-resident memory across runs.

---

## Standing evidence rule

No feature ships without its evidence recorded in DESIGN.md - a PR adding
behavior without a DESIGN.md entry is incomplete by definition.

---

## 8. Sources

**Anthropic (official):**
[Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) ·
[Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) ·
[Writing Tools for Agents](https://www.anthropic.com/engineering/writing-tools-for-agents) ·
[Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) ·
[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) ·
[Demystifying Evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) ·
[Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) ·
[Managed Agents](https://www.anthropic.com/engineering/managed-agents) ·
[Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) ·
[Skills](https://code.claude.com/docs/en/skills) ·
[Subagents](https://code.claude.com/docs/en/sub-agents) ·
[Hooks](https://code.claude.com/docs/en/hooks) ·
[Headless mode](https://code.claude.com/docs/en/headless) ·
[Fable 5 announcement](https://www.anthropic.com/news/claude-fable-5-mythos-5) ·
[Prompting Claude Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)

**OpenAI (official):**
[codex exec / non-interactive](https://developers.openai.com/codex/noninteractive) ·
[CLI reference](https://developers.openai.com/codex/cli/reference) ·
[Config reference](https://developers.openai.com/codex/config-reference) ·
[Goal Mode](https://developers.openai.com/codex/use-cases/follow-goals) ·
[Subagents](https://developers.openai.com/codex/subagents) ·
[AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md) ·
[Changelog](https://developers.openai.com/codex/changelog) ·
[Codex prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide)

**Evidence reviews (2026-06, architect-verified primary sources):**
[Geng & Neubig — async SE agents, worktree+manager topology](https://huggingface.co/papers/2603.21489) ·
[PEAR — weak planners hurt more than weak executors](https://arxiv.org/abs/2510.07505) ·
[AgentForge — execution-grounded role decomposition](https://arxiv.org/abs/2604.13120) ·
[ImpossibleBench — test-exploitation in coding agents](https://arxiv.org/abs/2510.20270) ·
[METR — SWE-bench-passing PRs mostly unmergeable](https://metr.org/blog/2025-08-12-research-update-towards-reconciling-slowdown-with-time-horizons/) ·
[Cross-Context Review — fresh-context judging wins](https://arxiv.org/abs/2603.12123) ·
[Chroma — context rot](https://www.trychroma.com/research/context-rot) ·
[OpenAI — harness engineering / AGENTS.md rot](https://openai.com/index/harness-engineering/) ·
[Cognition — multi-agents: what's actually working](https://cognition.ai/blog/multi-agents-working) ·
[OAgents — static vs dynamic decomposition on GAIA](https://arxiv.org/abs/2506.15741) ·
[AOrchestra — on-demand subagent construction](https://arxiv.org/abs/2602.03786) ·
[OpenAI BrowseComp — aggregation + failure modes](https://openai.com/index/browsecomp/) ·
[DeepResearch Bench leaderboard (RACE/FACT)](https://huggingface.co/spaces/muset-ai/DeepResearch-Bench-Leaderboard/blob/main/data/leaderboard.csv)

**Community / experts:**
[obra/superpowers](https://github.com/obra/superpowers) ·
[Ralph Wiggum loop](https://ghuntley.com/ralph/) ·
[A Brief History of Ralph](https://www.humanlayer.dev/blog/brief-history-of-ralph) ·
[Advanced Context Engineering (HumanLayer)](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents) ·
[Simon Willison — Agentic Engineering Patterns](https://simonwillison.net/guides/agentic-engineering-patterns/how-coding-agents-work/) ·
[Simon Willison on Fable 5](https://simonwillison.net/2026/Jun/9/claude-fable-5/) ·
[Latent Space — Harness Engineering](https://www.latent.space/p/harness-eng) ·
[Fable 5 Orchestrator Playbook](https://www.developersdigest.tech/blog/fable-5-orchestrator-model-playbook) ·
[GPT-5.5 effort curve (stet.sh)](https://www.stet.sh/blog/gpt-55-codex-graphql-reasoning-curve) ·
[GitHub Spec Kit](https://github.com/github/spec-kit) ·
[Steve Yegge — Beads](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a) ·
[Reward hacking in self-improvement](https://openreview.net/forum?id=ikrQWGgxYg) ·
[Obfuscated reward hacking](https://arxiv.org/pdf/2503.11926) ·
[Worktrees for parallel agents](https://engineering.intility.com/article/agent-teams-or-how-i-learned-to-stop-worrying-about-merge-conflicts-and-love-git-worktrees)

---

## 9. v4 evidence (in-session loop, verified 2026-07-02)

Per the standing evidence rule, this section records the five load-bearing
facts behind the v4 refactor (ADR 0001) that were not yet in the evidence
ledger.

**In-session three-role design basis.** Fresh context per unit of work, not a
fresh OS process, is the invariant Anthropic's own harness guidance treats as
load-bearing: fresh-context agent invocations are "equivalent to separate
sessions" ([Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)),
and Claude Code subagents start genuinely cold — "no parent conversation, no
parent file reads" ([Subagents](https://code.claude.com/docs/en/sub-agents)).
Both harnesses now productize that cold-context delegation natively: Claude
Code's Agent tool plus custom agent definitions (`model`, `tools`,
`disallowedTools`, `permissionMode`, `isolation: worktree`, `background`,
working in CLI **and** Desktop), and Codex's native subagents (`spawn_agent`,
`send_input`, `resume_agent`, `wait_agent`, `close_agent`, `max_threads` 6,
`max_depth` 1 — [Codex Subagents](https://developers.openai.com/codex/subagents)).
Full source list: `docs/spec/v4-orchestrator-loop.md` §2 items 1 and 4.

**D9 — desktop subagent Bash strip.** Three independent human-run desktop
canaries falsified the initial hypothesis and narrowed the root cause. VG8
run 1 (toy2, freeze `effc321`, lane `15433ed`): both subagents denied Bash at
spawn. WG5 = VG8 re-run after padding tools per the (falsified) positional
theory (toy3, freeze `fddcec6`, lane `e0fbfdb`): padding did not restore
Bash — builder kept `Glob,Read,Edit,Write,Grep`, judge kept `Glob,Read,Grep`,
proving the strip targets Bash by name, not position. VG8 run 3, foreground
dispatch variant (toy4, freeze `c694398`, lane `0c7e1e3`, finding `79d5755`):
still no Bash even fully synchronous, proving the strip happens before any
permission-prompt layer could apply. Upstream sources:
[claude-code#60237](https://github.com/anthropics/claude-code/issues/60237)
(first/last `tools:` entries dropped at spawn — the pattern this repo's own
canaries falsified for desktop),
[claude-code#18749](https://github.com/anthropics/claude-code/issues/18749)
(Bash-specific variant, closed not-planned, matches the observed desktop
behavior), and
[Permission modes](https://code.claude.com/docs/en/permission-modes)
(non-prompting contexts auto-deny tool calls that aren't pre-allowed —
background subagents can't prompt). Session-log anchors:
`docs/HANDOFF.md` rows dated 2026-07-02 for the VG8 (×2) and WG5 desktop-canary
entries.

**PowerShell second-executor fix + live judge usage.** Slice `v4-desktop2`
(freeze `588a3e9`, lane `74f8221`) added `PowerShell` as a second, interior
(padded) executor to both agent definitions with matching deny mirrors, to
route around the Bash-specific strip. Decisive evidence: the judging
subagent itself held and used the native PowerShell tool on the CLI to run
gates XG3/XG6 — first live proof either executor works in a cold subagent
under the new defs. Anchor: `docs/HANDOFF.md` v4-desktop2 lane+judgment row,
2026-07-02; gate IDs XG2/XG3/XG6 in `docs/gates/v4-desktop2.md`.

**D11 — CLI subagent spawns unisolated despite `isolation: worktree`.**
Discovered live during the `v4-desktop` builder lane (cold architect-builder
subagent, sonnet:high, working tree → commit `1d84230`): a Claude Code CLI
spawn of an agent definition carrying `isolation: worktree` frontmatter did
not create a worktree, contradicting the frontmatter's documented guarantee.
`skills/architect/dispatch.md`'s per-harness delegation table now tells
Claude-backend lanes to verify with `git worktree list` after spawn rather
than assume isolation. Anchor: `docs/HANDOFF.md` v4-desktop lane row,
2026-07-02.

**Codex 0.139 native `spawn_agent` round-trip canary.** One codex 0.139.0
thread spawned exactly one child agent instructed to reply `PONG`; the parent
surfaced `SPAWN_RESULT: PONG` after `wait`ing on it — proving the native
collab-tool round trip end to end. Raw evidence:
`.architect/tmp/codex-spawn-canary/events.jsonl` (architect-run, this
machine; `item.completed` records `"tool":"spawn_agent"` then
`"tool":"wait"` with `"message":"PONG"`, followed by the parent's
`agent_message` item `"SPAWN_RESULT: PONG"`) and `prompt.md` in the same
directory. Judged independently: slice `v4-codex` judgment (commit `ca78b71`)
re-ran the canary and recorded gate CG4 PASS in `docs/gates/v4-codex.md`.
This canary is also the source of the `wait` vs `wait_agent` naming note in
`skills/architect/dispatch.md` — the collab event stream names the tool
`wait`, while the docs and PRD call it `wait_agent`.

---

## 10. Loop-hardening evidence (P1–P7, verified 2026-07-02)

Human-approved research-driven hardening (`docs/HANDOFF.md` Decisions log,
2026-07-02, "Human APPROVED P1–P7" row), shipped in slice `loop-hardening`
(freeze `6f64bd1`, lane `977c7b6`, cold judge LG1–LG9 all PASS). P1–P6 are
argued in `docs/research/loop-improvements.md`; P7 is not — its rationale
lives only in the Decisions-log row cited above.

**P1 — ban silent fallbacks and unrequested backcompat shims.** The builder
block and `architect-builder` agent definition now forbid success-shaped
defaults and unrequested backwards-compatibility code, fail loudly by
default, with the sole exception of explicitly-specced resilience fallbacks.
Primary-source language: OpenAI's
[Codex Prompting Guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide)
bans "broad catches or silent defaults... no silent failures"; practitioner
precedent in
[claude-code#21027](https://github.com/anthropics/claude-code/issues/21027)
("NEVER use fallback values - they hide errors and mask problems"). The
gate-gaming mechanism (a silent fallback can fake passing output while the
primary path is broken) and Fowler's YAGNI four-cost framework for
unrequested compat code have no citable primary URL; see
`docs/research/loop-improvements.md` Q5.

**P2 — pre-freeze spec grill.** One cold, read-only subagent falsifies the
draft gate file before it freezes — running each gate command against the
current tree, verifying referenced paths exist, and attacking acceptance
criteria for non-falsifiability. Default on for the first slice in a repo and
for high-stakes slices. Evidence:
[Cross-Context Review](https://arxiv.org/abs/2603.12123) (fresh-session
review F1 28.6% vs same-session self-review 24.6%, p=0.008; reviewing twice
in the same session did not beat once); the
[20,574-session misalignment study](https://arxiv.org/abs/2605.29442) (41%
of Wrong-Project-Diagnosis failures stem from Premature Action — the
first-time-unfamiliar-repo case); CRITIC's tool-grounded-critique result
(+7.7 F1), uncited by URL in `docs/research/loop-improvements.md` Q2. The
research doc's own proposal figure was this repo's pre-P2 history: 2 spec
defects that shipped past PHASE 0 into frozen gates (repo-name grep
collision; bookkeeping-commit enumeration). The as-shipped, first-use result
differs: slice `loop-hardening`'s own grill caught 5 draft-gate defects
before freeze (`docs/HANDOFF.md` TL;DR, 2026-07-02 loop-hardening bullet:
"The pre-freeze grill (P2) validated itself on its first use: 5 draft-gate
defects caught before freeze").

**P3 — slice-size discipline.** Judged diffs target ≤~400 changed lines;
a spec whose diff will exceed that should be split into more lanes or more
slices. Evidence: batch/position-bias degradation literature and human
code-review effectiveness falling off past ~200–400 LOC per pass (SmartBear/
Cisco, no citable primary URL) plus
[Chroma's Context Rot](https://www.trychroma.com/research/context-rot)
(degradation "at every increment, not just near the limit," across 18
models); see `docs/research/loop-improvements.md` Q1.

**P4 — repeated-identical-action stall signal.** The stall doctrine now
names a repeated identical action/query as a stuck signal, not just silence
or missing artifacts. Evidence: OpenHands SDK's same-action-repeated stuck
detector (no citable primary URL) and
[SWE-Marathon](https://arxiv.org/abs/2606.07682), where the worst scaffold
repeated 32% of tool calls and produced 63/83 timeouts; see
`docs/research/loop-improvements.md` Q3.

**P5 — skill-text instruction-budget guard.** The validator now warns when
total skill-text imperative-instruction count crosses a ceiling. The
research doc's proposal figure was ~150–200 imperative instructions total
(HumanLayer/RPI: models "silently skip" steps past that range — direct
quote, no citable primary URL in `docs/research/loop-improvements.md` Q3).
The as-shipped guard differs: the validator's threshold is 800 non-blank
lines, measured at 557 post-change (`docs/HANDOFF.md` TL;DR, 2026-07-02
loop-hardening bullet: "800-non-blank-line size guard (at 557
post-change)").

**P6 — tier-up over retry.** The alias-table note now says: when a lane fails
once, prefer raising its model tier over re-running the same tier. Evidence:
Anthropic's
[Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
post — "upgrading [the subagent model] is a larger performance gain than
doubling the token budget"; see `docs/research/loop-improvements.md` Q4.

**P7 — docs-debt convention.** Memory docs (`docs/HANDOFF.md`) update
continuously per block; product docs (`README.md`, `DESIGN.md`) are never
edited by build lanes or the orchestrator mid-slice — they batch into one
dedicated docs lane at the milestone/PR boundary, fed by a running docs-debt
list in the handoff (one pointer line appended per CONTINUE verdict). Not
in `docs/research/loop-improvements.md` — the rationale (disjoint lane
file-sets, README as the highest-contention file, evidence rows needing
post-judgment information, product text never brain-written) is recorded
only in `docs/HANDOFF.md`'s Decisions log, 2026-07-02, "Human APPROVED P1–P7"
row. This lane (`v4-docs`) is the convention's first dedicated-docs-lane
consumption of the Docs debt table.

---

## 11. Research-loop evidence (A1-A4 + config parity, verified 2026-07-02)

Slice `research-loop` (freeze `1b2fd90`, lane `3f46f09`, merge `e39d0f4`)
implemented calibrations A1–A4 from the r2 research report
`docs/research/agent-pipeline-patterns.md` (commit `b2a7766`), plus
brain/brawn config parity with `/architect`.

**Evidence base and verdicts.** The r2 report's own table: KEEP the current
orchestrator-plus-parallel-researchers shape (K1–K4, independently
converged on by Anthropic, Google, LangChain, and Cognition — "writes stay
single-threaded"); ADD four calibrations (A1 numeric return cap, A2
draft-as-state gap round, A3 tool-call-calibrated budgets, A4 name the
research handoff); DON'T ADD two rejected proposals — D1 extra
coordination layers (architectural bloat, 58–515% overhead) and D2
cache-alignment machinery (harness-owned; our ~250-token preamble sits
below OpenAI's 1024-token cache minimum). Field-consensus finding: no
simpler industry-standard pipeline exists — the available improvements are
calibrations, not restructurings.

**The 2,500-token cap.** A1 shipped at ~2,500 tokens, not the report's
proposed ~1,500 — a human amendment measured on this repo's own r2 lanes
(2,000–3,600 tokens per lane with citations; URLs alone cost 138–966
tokens; the worst lane double-cited every URL). Findings now cite sources
by tag against a single numbered source list per lane, removing that
double-citation waste.

**Grill's third consecutive catch.** The pre-freeze grill (P2, §10) caught
2 blocking gate defects before `research-loop`'s gates froze: a vacuous
PowerShell exit-code check (RG1) and an unenumerable touch set (RG7), plus
4 non-blocking sharpenings. This is the mechanism's third consecutive
catch, after `loop-hardening`'s first use (5 defects) and `v4-docs`'s
second (8 defects) — the grill has found real defects on every use so far.

**D12 — intermittent, def-asymmetric CLI subagent tool strip.** Same
session, same day: a cold architect-builder spawn held both Bash and
PowerShell, while two consecutive architect-judge spawns lost both shell
tools (Glob/Read/Grep only) — not Bash-only like desktop's D9 (§9), and
not the first/last positional pattern of claude-code#60237 (Glob first and
Grep last both survived). Both judge spawns correctly returned INVALID.
The precedent that resolved it: composite judgment across a cross-family
codex judge (gpt-5.5 xhigh, workspace-write, tree audited untouched after)
for the shell-dependent gates, plus a cold headless `claude -p` session for
the one gate the codex sandbox cannot run at all — Git Bash dies with
Win32 error 5 under the codex sandbox on this machine.

---

## 12. v5 - the autonomous factory

v5 is the approved replacement for the interactive per-slice loop described in
the older sections above. The source of truth is
`docs/spec/architect-v5.md`, backed by
`docs/research/autonomous-software-factory.md` and
`docs/research/skill-prompt-patterns.md`. Earlier v4 notes remain historical
evidence; where they conflict with v5, the v5 spec and shipped skill files win.

### D1-D11 summary

- **D1 roles.** The running session is the brain: intake, spec, issue DAG,
  blocker answers, judge dispatch, merge decisions, and final digest. Brawn
  lanes code only. Judges are cold brain-tier verdict agents. Monitors detect
  stalls only.
- **D2 model config.** `.architect/config`, then `~/.architect/config`, then
  dispatch defaults resolve brain, brawn, monitor, and judge roles. Default
  brawn is same-family tier-down. Cross-family brawn is explicit config, not a
  hidden default.
- **D3 intake.** The brain asks at most about five materiality-gated questions
  in one batch; unanswered or lower-value gaps become spec assumptions for the
  human to veto.
- **D4 spec gate.** The human reviews one `docs/spec/<project>.md` file.
  Approval authorizes the whole issue DAG.
- **D5 decomposition.** The brain compiles the spec into one epic plus
  sub-issues, native parent links, and native blocked-by edges. Gates freeze in
  git under `docs/gates/`; one grill pass attacks the whole decomposition.
- **D6 monitoring.** Each dispatch wave can run up to five brawn lanes plus one
  cheap monitor. The monitor sweeps roughly every 10 minutes for output growth,
  process activity, and repeated-command tails; it exits with evidence and
  never kills or decides.
- **D7 failure and blocker handling.** Brawn posts an exact blocker and stops.
  The brain answers durably on the issue and respawns a fresh lane with the
  answer. Judge failures drive input fixes or re-decomposition, not automatic
  tier movement.
- **D8 communication.** GitHub issues are the durable coordination log:
  PHASE-0 comments, blocker comments, rulings, verdicts, and the epic digest.
  Lane reports remain raw evidence artifacts and are mirrored when direct `gh`
  access is unavailable.
- **D9 design-quality doctrine.** The brain applies the oddity rule,
  tidy-first issue splitting, design-it-twice for new load-bearing
  abstractions, interface handoff blocks, reviewer calibration, and the codify
  step to `docs/solutions/`.
- **D10 skill-writing craft.** `SKILL.md` stays thin and pointer-based;
  operational detail lives in `dispatch.md` and `loop.md`, with the
  800-non-blank-line size guard retained.
- **D11 safety rails.** `docs/STOP`, irreversible actions, two consecutive
  KILLs, assumption-colliding blockers, builder gate edits, scope growth, and
  high-stakes review requirements remain hard stops.

### Human rulings, 2026-07-02

- No automatic tier movement. Tier is fixed at decomposition by config and
  dispatch rules; a failure is diagnosed as a spec, context, or architecture
  problem. This supersedes section 10's P6 tier-up-over-retry note.
- No per-command kill ceilings. Issues and gates may carry duration hints;
  liveness is output growth plus process activity, not elapsed time alone.
- The monitor is detection-only. It runs about every 10 minutes, exits with
  anomaly evidence, and wakes the brain to rule the next action.
- The scope-challenge rubric from the research pass was removed from D9.
- TDD lessons are sourced from Matt Pocock's `tdd` skill: confirm seams in the
  spec and issue body, write behavior tests through public interfaces, use
  tracer-bullet slices, never refactor while RED, and name the highest-value
  behaviors rather than pretending every path can be tested.

### Dogfood evidence from issues #12-#18

The v5 build was dogfooded as a real GitHub issue DAG. Issue #12 was the epic
and raw coordination trail. Issue #13 shipped the top-level architect skill
rewrite (`docs/lanes/v5-skill-core-01.md`). Issue #14 shipped the factory loop
reference (`docs/lanes/v5-loop-factory-01.md`). Issue #15 shipped dispatch,
model routing, issue conventions, monitor dispatch, and respawn guidance
(`docs/lanes/v5-dispatch-01.md`). Issue #16 shipped the builder, judge, and
monitor agent definitions (`docs/lanes/v5-agents-01.md`). Issue #17 retired
the old handoff machinery from shipped skill/install surfaces
(`docs/lanes/v5-handoff-retire-01.md`). Issue #18 is this dedicated docs-debt
lane.

The run also produced four diagnoses worth codifying:

- **D12 recurred beyond judges.** Multiple Claude-backend subagent spawns lost
  both Bash and PowerShell during the 2026-07-02 v5 session: grill/judge work
  plus builder lanes reported shell-dependent gates as unrunnable. The durable
  rule is explicit BLOCKED-with-evidence for shell-stripped builders, and
  recorded Codex-backend or PowerShell same-pattern substitutions for lanes and
  judges that can execute them.
- **uv cache needed a sandbox redirect.** `uv run --no-project python
  tests/validate_skills.py` failed when uv tried to write under AppData in the
  Codex sandbox; `UV_CACHE_DIR=.architect/tmp/uv-cache` kept cache writes
  inside the workspace and let validator gates run.
- **Touch-set disjointness was insufficient.** A later docs lane still linked a
  file that issue #17 deleted. The fix is a reference sweep for deleted or
  renamed files before freezing boundaries, and suspicion of any builder-added
  validator exception.
- **Worktree snapshots must be verified after spawn.** The first
  harness-created worktree had a fast-forwarded ref but stale files on disk.
  Freeze commits must precede dispatch, and each lane must verify HEAD and
  required input files before building.

### v5.1 addendum - architect-v5.1

Source pointers: the approved spec is `docs/spec/architect-v5.1.md`; this run's
trail is epic #20 with issues #21-#25 on `factory/v5.1` from spec approval
commit `0a60bb6`; the in-repo ruling record is
`docs/lanes/v51-docs-rulings.md`.

Eight retro findings, paired as R/W summaries:

- **R1/W1.** BLOCKED-with-evidence and respawn worked, but Claude-backend
  shell-strip made backend choice an intake-time risk.
- **R2/W2.** PHASE 0 caught an orchestrator defect, while the first harness
  worktree still proved freeze visibility must be checked before dispatch.
- **R3/W3.** Cold judge diff-vs-intent caught a masked failure, but the grill
  missed issue-body, deleted-reference, and ignored-new-file classes.
- **R4/W4.** One decomposition grill caught five draft defects, yet
  post-freeze rulings lacked a durable in-repo home.
- **R5/W5.** INVALID-vs-FAIL discipline held, while codex-backend judge blocks
  and cache substitutions were still hand-assembled.
- **R6/W6.** Interface handoff blocks avoided merge conflicts, but monitor
  teammate spawns idled instead of matching the documented quiet-exit model.
- **R7/W7.** Raw evidence under tool deprivation stayed honest, while direct
  builder issue posting was effectively unavailable and required orchestrator
  mirroring.
- **R8/W8.** Sonnet-high brawn passed most first-wave lanes, but branch hygiene
  was improvised by landing pre-factory commits on main before the run branch.

v5.1 design decisions:

- **D1. Backend canary at preflight.** Run a trivial shell canary per candidate
  backend, mark shell-less backends DEGRADED, and select the verified fallback
  before decomposition.
- **D2. Factory branch and freeze-push-dispatch.** Cut `factory/<run>` at spec
  approval, commit and push the freeze, then verify spawned worktree HEAD and
  frozen inputs.
- **D3. Wider decomposition grill.** Grill gates, issue bodies, deleted or
  renamed references, and committability for new artifact paths.
- **D4. Rulings file.** Keep post-freeze intent in append-only
  `docs/lanes/<slug>-rulings.md` files owned by the orchestrator.
- **D5. Codex judge template and substitution table.** Freeze the codex judge
  block and sanctioned substitutions in dispatch text.
- **D6. Monitor spawn semantics.** Treat the monitor as a background subagent;
  teammate-style monitor spawns require explicit stand-down.
- **D7. Issue mirror reality.** Accept `MIRROR: ORCHESTRATOR` as normal when
  builders cannot post to GitHub directly.
- **D8. Keep-list.** Preserve blocker exits, PHASE 0 duty, cold judging, one
  grill, interface blocks, raw substitutions, INVALID discipline, and tier
  outcome logging.

First live D1 exercise: the v5.1 preflight backend canary returned
`CANARY: DEGRADED` for a Claude haiku architect-builder spawn with
Glob/Read/Edit/Write/Grep only and no shell; cumulative shell-strip evidence on
2026-07-02 was 6/6 Claude subagent spawns. The backend selected at preflight for
the whole v5.1 run was codex/tier-down (`gpt-5.5`, high effort), and no
mid-wave backend switching occurred.
