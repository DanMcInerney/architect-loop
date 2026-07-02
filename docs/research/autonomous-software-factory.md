# Autonomous software factory: brain/brawn patterns for /architect v5

Research handoff, 2026-07-02. Raw lane findings in `.architect/research/r3-*`
(gitignored). Researcher: codex/tier-down (gpt-5.5, effort high), 7 lanes +
scout across 2 waves; orchestrator verified load-bearing claims against
primary sources directly.

## The brief

Refactor /architect so the brain model handles intake with the fewest
possible human questions → writes a product spec → one human review gate →
decomposes the spec into GitHub issues designed for maximum parallelism →
dispatches up to 5 brawn subagents in worktrees → answers their questions,
clears blockers, detects stalls, continues-or-respawns until every issue is
closed. Brawn state lives in GitHub issues, not HANDOFF.md. Named study
targets: Matt Pocock's skills, vincentmvdm's middle-manager gist, other
autonomous-factory designs.

## Answer first

The design is buildable today and the field has converged on almost exactly
this shape — the ecosystem name for it is **orchestrator-workers over
issue/PR state** (Anthropic's taxonomy term), popularized in 2026 as the
**"middle manager" pattern**. Every component has a working precedent:

1. **Intake**: don't grill, don't go silent — use a *materiality gate*.
   GitHub Spec Kit's `/clarify` asks **at most 5 questions**, each justified
   by "would the answer materially change implementation or validation
   strategy?", and everything else becomes a recorded **`## Assumptions`**
   section in the spec that the human vetoes at the review gate. This is the
   established middle path between Pocock's maximal `/grill-me` and his
   zero-question `/to-prd`. [VERIFIED]

2. **Spec → issues**: Pocock's `/to-issues` mechanics are the template —
   tracer-bullet **vertical slices** ("narrow but complete end-to-end,
   demoable on its own"), each issue carrying *What to build / Acceptance
   criteria / Blocked by*, published in dependency order. **The parallel set
   is the unblocked frontier of the dependency DAG**, not "everything at
   once." His open PR #410 (`/to-spec`, `/to-tickets`) makes this explicit:
   tickets as "a parallelizable DAG (real tracker, native blocking links)".
   [VERIFIED]

3. **Issues as state**: GitHub now natively supports the whole graph — issue
   dependencies (blocked-by/blocking, GA 2025-08-21, REST + GraphQL), sub-
   issues, issue types, and `gh` CLI v2.94.0 (2026-06-10) grew
   `--blocked-by`/`--parent`/`--blocking` flags *explicitly because "coding
   agents rely on gh"*. No body-text conventions needed. [VERIFIED]

4. **Supervisor loop**: the middle-manager gist is the operating manual —
   the brain **never writes code and never reads big diffs** ("a polluted
   context window kills the whole factory"); it dispatches fresh workers,
   answers their questions from spec/issue context, batches rare human
   escalations, and delegates done-checking to **verifier agents**. Gas Town
   supplies the only published liveness mechanics: heartbeat patrols,
   stalled/zombie/orphaned-work signals, and **3+ crash-loops → escalate**.
   [VERIFIED]

5. **Continue vs respawn**: the surveyed systems that run longest unattended
   (Ralph, Gas Town) both **respawn fresh sessions and keep memory external**
   (git history, progress files, issue state) rather than resuming polluted
   contexts. Devin's resumable-VM sessions are the counter-model; nobody
   published evidence that resuming beats respawning. [VERIFIED convergence]

6. **Concurrency = 5 is the right cap.** Claude Code's own docs: "Start with
   3-5 teammates… Three focused teammates often outperform five scattered
   ones"; Osmani independently: 3-8 with review bandwidth as the limiter;
   token cost scales linearly. Worktrees give *file* isolation only —
   runtime collisions (ports, DBs, dev servers) need per-lane setup scripts
   (Conductor allocates 10 ports per workspace and has a `nonconcurrent`
   escape hatch). [VERIFIED]

7. **The hard boundary is verification, not generation.** This is the single
   strongest cross-source result: MAST (1,600+ traces, κ=0.88) puts
   verification failures at 23.5% and its enterprise follow-up names
   *incorrect verification* the strongest failure predictor ("agents declare
   victory without checking ground truth"); a June 2026 study of 33,596
   agent-authored PRs found **80.2% of agent-written test patches have weak
   or no real assertions** — agent-authored "tests pass" is a weak oracle.
   Every credible factory design externalizes verification: Gas Town's "you
   can't stamp your own work," the gist's "never mark work off on an agent's
   say-so," Claude Code's `TaskCompleted` hook that can reject completion.
   [VERIFIED]

The two claims the design should NOT lean on: (a) full no-review autonomy —
the expert field splits hard on it and the failure evidence (below) sides
with keeping the spec gate plus machine-verifiable completion gates; (b) the
assumption that **cheap brawn under a frontier brain is a settled pattern —
it is not** (DISPUTED, below). Keep brawn configurable and expect to run
frontier-tier brawn on judgment-heavy issues, mirroring the gist's per-task
tier policy.

## Major findings

### F1. Intake: materiality-gated questions + assumption log [VERIFIED]

- Spec Kit `/clarify`: cap 5 questions, ask only when the answer "materially
  change[s] implementation or validation strategy"; answers encoded into a
  `## Clarifications` section; unasked gaps become `## Assumptions` the
  reviewer can veto. [primary, repo current 2026-07]
- Devin gates on confidence: low confidence → "wait for user approval before
  proceeding"; high → proceed. [primary, 2025-05]
- Evidence base: ClarifyGPT (FSE 2024) lifted GPT-4 MBPP Pass@1 70.96→80.80%
  by targeted clarification; SAGE-Agent (2025) cut clarifying questions
  1.5–2.7× while *raising* coverage 7–39% using expected-value-of-information;
  "Ask or Assume?" (2026) shows uncertainty-aware asking beats both extremes
  on underspecified SWE-bench. [primary papers]
- **Implication**: brain asks one batched round of ≤5 load-bearing questions
  at intake (our AskUserQuestion supports 4/call), records everything else as
  named assumptions in the spec. The human review gate doubles as assumption
  veto. **Dispute to note**: Spec Kit deliberately asks its ≤5 questions ONE
  AT A TIME (adaptive: each answer can eliminate later questions); no
  measurement comparing batch vs sequential was found (NOT FOUND, wave 2).
- *Would change this*: a measurement showing sequential clarification
  materially beats batched for spec quality.

### F2. Decomposition: vertical slices on a native dependency DAG [VERIFIED]

- `/to-issues` (primary, repo): "independently grabbable" = vertical slice —
  end-to-end through schema/API/UI/tests, demoable alone; body carries
  Parent / What to build / Acceptance criteria / Blocked by; publishes
  blockers-first so later tickets reference real issue IDs; asks exactly 3
  decomposition-approval questions (granularity, deps, merge/split).
- AFK vs HITL classification per issue (agent-runnable vs needs-human-
  judgment) — in our design HITL issues route to the *brain*, not the human,
  unless they collide with a recorded assumption.
- GitHub natively stores the DAG: dependencies GA 2025-08-21 (50 links/type,
  `is:blocked`/`blocking:` filters, REST + GraphQL `addBlockedBy`); sub-issues
  + issue types (preview 2025-01); `gh` 2.94.0 flags (2026-06-10). I verified
  the changelog and PR #410 directly. [primary]
- **Implication**: scheduler = "dispatch every issue whose blockers are
  closed, up to the 5-agent cap." No custom state files; `gh issue list
  --blocked-by`-style queries are the whole scheduler state.

### F3. Issues as the brawn communication channel — with one trap [VERIFIED]

- Copilot coding agent precedent: it snapshots the issue at assignment and
  **does not read issue comments posted after it starts** — progress and
  iteration move to the PR (checklist in PR body, commits, session log).
  [primary, GitHub docs 2026-07]
- **Implication for us**: writing "answers" onto the issue does NOT reach a
  running brawn agent by itself. The channel must be: brawn posts
  question/blocker as an issue comment and *stops*; brain answers on the
  issue and **respawns (or messages) the agent with the answer in the spawn
  context**. The issue thread is the durable log; the delivery mechanism is
  the spawn/message, exactly like the gist (fresh session per issue,
  answers injected by the manager).
- Platform limits (primary, GitHub docs): secondary rate limits are opaque
  (hot comment loops risk integration bans), comment cap 65,536 chars, every
  comment notifies watchers. Post per-milestone/blocker/done, not per-commit.
- No official claim/lease protocol exists for agents grabbing issues
  (NOT FOUND) — assignment is the primitive. A single brain dispatcher
  sidesteps the race entirely; don't build worker self-claim on GitHub.

### F4. Supervisor loop: dispatch, monitor, unblock, verify [VERIFIED]

Converged mechanics across the gist (primary), Gas Town (primary docs),
Ralph (primary), and Claude Code Agent Teams docs (primary):

- **Brain never codes, never reads raw diffs** — verifier subagents do
  ("that's what verifiers are for" — gist). Protects the orchestrator
  context, same reason as our existing return-cap discipline.
- **Stall detection** (Gas Town, the only system with published signals):
  patrol cadence ~3-min heartbeat; signals = no progress on claimed work,
  zombie/orphaned sessions, repeated crash of the same step; **3+ repeats →
  escalate** instead of retrying harder. The gist adds: agents idle "waiting
  for CI" is a named stall class — never let a worker idle on a check the
  supervisor can resolve. Our loop-hardening "repeat-action stall signal"
  already matches this.
- **Escalation policy** (gist): worker questions answered by the manager
  from issue/spec/docs immediately; only design/product decisions absent
  from the spec go to the human, batched, on a public channel, and the
  manager keeps polling for the reply — "if you ask a question and never
  check back, the answer might as well not exist."
- **Completion**: `TaskCompleted`-style gates that can *reject* the done
  claim with feedback (Claude Code hooks, exit code 2), or Gas Town's
  Refinery (bors-style merge queue; failed verification → re-dispatch).
- **Respawn over resume**: Ralph "each iteration is a fresh instance with
  clean context," memory in git + progress files; Gas Town "persistent
  identity, ephemeral sessions" — one step per session, worktree persists.
  Matches our cold-builder philosophy; extend it to blocker recovery.

### F5. Runtime substrate: what Claude Code gives us today [VERIFIED, my fetch]

- Agent Teams (experimental, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`): shared
  task list **with dependencies that auto-unblock**, file-locked task
  claiming, mailbox (`SendMessage`), teammate plan-approval by the lead,
  `TeammateIdle`/`TaskCreated`/`TaskCompleted` hooks. But: **teammates are
  NOT worktree-isolated** ("Two teammates editing the same file leads to
  overwrites"), no nested teams (a teammate cannot spawn subagent fleets),
  one team per session, no session resumption of teammates, "task status can
  lag" (docs admit teammates sometimes fail to mark tasks complete — i.e.
  first-party confirmation of the stall class).
- Subagents (what v4 uses): isolated, report-only, lower token cost — docs
  position them for exactly the report-back worker role; worktree isolation
  available. D12 (intermittent shell-tool strip on spawns) remains our local
  watch item.
- **Implication**: GitHub issues as durable state + our own dispatch loop
  over background subagents remains the safer substrate than Agent Teams
  today; adopt Agent Teams primitives (hooks, mailbox) when they exit
  experimental. Token math (Anthropic primary): multi-agent ≈ **15× chat
  tokens**; Agent View docs: 10 parallel agents burn subscription quota
  ~10× faster.

### F6. Concurrency cap and integration discipline [VERIFIED]

- 5 agents: inside both published ranges (Claude docs 3-5 "no hard limit,
  linear cost"; Osmani 3-8 — independent origins). The binding constraint
  every source names is *review/verification bandwidth*, which in our design
  is the brain — so cap concurrency by the brain's verification queue, not
  by CPU.
- Integration: one **serialization point** — Sawyer Hood's dedicated merger
  agent ("branches get merged, conflicts get resolved, and tests pass"),
  Gas Town's Refinery, GitHub merge queues. Parallel lanes must not
  self-merge. Conflicts on the same file are a *decomposition* failure
  (Claude docs: partition files per lane) before they are a merge problem.
- Worktree lifecycle: copy gitignored env via `.worktreeinclude` (Conductor
  and Claude Code `--worktree` both), per-lane ports (Conductor: 10/lane),
  setup/archive scripts, and a `nonconcurrent` fallback for shared-resource
  repos. Anthropic's C-compiler experiment (2,000 sessions, 16 agents,
  $20k) demonstrates the ceiling case works when tasks are cleanly
  subdivided and tests are the oracle. [primary, 2026-02]

### F7. Failure evidence that bounds the autonomy [VERIFIED]

- MAST (arXiv 2503.13657 v3, 2025-10; 1,600+ traces, 7 frameworks, κ=0.88;
  category shares from paper body): system-design failures 44.2% (step
  repetition 15.7%, termination-unaware 12.4%), inter-agent misalignment
  32.3% (reasoning-action mismatch 13.2%), verification 23.5%. Its
  interventions (better prompts, topology) improved but did NOT eliminate
  failures — ChatDev 25.0→40.6% on ProgramDev. Multi-agent structure itself
  generates failure classes single agents don't have.
- ITBench follow-up (IBM+Berkeley, 2026-02): FM-3.3 *incorrect verification*
  is the strongest failure predictor across models.
- "All Smoke, No Alarm" (arXiv 2606.18168, 2026-06; abstract verified):
  80.2% of 86,156 agent test patches weak/no oracle → **completion gates
  must run pre-existing or brain-approved tests, not brawn-authored ones**.
- METR RCT (2025-07, primary): experienced devs 19% *slower* with AI while
  believing 20% faster; 2026 update walks the generalization back
  (CIs span zero) but hardens the lesson: **self-reports and "feels done"
  are unreliable — measure with external oracles.**
- Replit incident (2025-07, med confidence, multiple secondary + CEO
  statement): unattended agent with prod write access deleted a production
  database — autonomy amplifies permission mistakes. Brawn agents get
  worktree-scoped write, nothing else; anything irreversible stays behind
  the brain.

## Disputed / unsettled

- **Brain/brawn model tiering** — DISPUTED. The gist tiers explicitly
  (ultra for judgment + verification, GPT-5.5-high as workhorse). But Yegge
  runs Gas Town swarms on frontier Opus, and Osmani's routing puts
  *implementation* on Opus/Sonnet with a frontier read-only reviewer per 3-4
  builders. No source demonstrates cheap-model coders under a frontier
  supervisor as reliably sufficient. Positions differ by workload (bulk
  recipe-like issues tolerate cheaper models; judgment-heavy ones don't).
  Keep per-issue tier routing (we already have dispatch rules); default
  brawn stays tier-down, with tier-up-over-retry.
- **Full-AFK vs review-bottleneck** — DISPUTED (see expert map). The
  evidence-backed middle: unattended *between* gates, with machine
  verification at issue completion and the human at spec approval + final
  merge. Willison's scoping is useful: full-AFK is proven for research/
  bulk/tightly-specified work, not for production-shaping decisions.
- **Batch vs sequential clarifying questions** — OPEN. Spec Kit is
  deliberately sequential-adaptive; our UX goal (fewest interruptions)
  favors one batch. NOT FOUND: any measurement. Cheap to test on ourselves.

## Expert positions map

| Expert | Position (dated) | COI |
|---|---|---|
| Geoffrey Huntley (Ralph) | Full AFK: "I don't review the code… autonomously push to master" (2026-01) | promotes own loop pattern |
| Steve Yegge (Gas Town) | Factory-bullish, "very powerful, definitely sloppy," still "manual steering" (2026-01) | sells the tool/book |
| Vincent van der Meulen | Single orchestrator over parallel cloud agents; high parallelism "too mentally taxing," "brutal merge conflicts" (2026-02) | gist author |
| Sawyer Hood | Middle manager + merger agent; "not convinced… 100% production ready yet" (2026-02) | builds workflow tooling |
| Matt Pocock | AFK works for backlogs, but stage through HITL first; alignment before autonomy (2026) | paid educator |
| Addy Osmani | "The bottleneck is no longer generation. It's verification"; 3-5 sweet spot; "80% problem" pullback (2026-01/03) | Google, personal views |
| Simon Willison | Review is the hard limit; full-AFK only for code research, unreviewed output is "slop" (2025-10/11) | independent |
| Anthropic eng | Long unattended runs feasible in harnesses with test oracles ($20k C compiler, 2026-02); multi-agent 15× tokens | vendor |

Sharpest genuine disagreement: Huntley/Yegge (ship without human review) vs
Willison/Osmani/Pocock/Hood (verification is the bottleneck and the safety
system). Where they *agree* — externalized verification, fresh contexts,
issue-tracker state, decomposition quality determining parallelism — is the
solid ground this design stands on.

## Open questions → next round inputs

1. **Batch-vs-sequential clarification**: no published measurement. Resolve
   empirically: run both intake styles on 2-3 real specs, compare gap counts
   found at the human review gate.
2. **Cheap-brawn sufficiency**: does tier-down brawn pass frozen gates at
   the same rate as frontier brawn on recipe-like issues? Our own loop can
   A/B this; log per-tier gate pass rates.
3. **GitHub comment-rate ceiling**: secondary limits are undocumented.
   Establish a safe posting cadence (per-milestone, ≥1 min spacing) and
   watch for 403s; no search will answer this.
4. **Agent Teams maturation**: hooks (`TaskCompleted` reject, `TeammateIdle`
   nudge) are exactly our supervisor primitives — track when teams exit
   experimental and gain worktree isolation. Re-check quarterly.
5. **Stall thresholds**: Gas Town's 3-min heartbeat / 3-crash escalation are
   the only published numbers; tune ours from live runs, not literature.

## Method

Scout + 5 designed wave-1 lanes + 2 gap lanes (experts, intake), codex
gpt-5.5-high read-only w/ live web search, ≤2,500-token findings each, all
lanes returned clean. Orchestrator independently fetched: the middle-manager
gist, mattpocock/skills README + PR #410, Sawyer Hood post, Claude Code
agent-teams docs, GitHub dependencies changelog, MAST + oracle-study
abstracts. Every load-bearing claim above carries ≥2 independent origins or
is tagged as single-source primary. Do-not-rechase list (NOT FOUND): HN
threads on the gist/Hood post; official GitHub issue-claim lease protocol;
Claude Squad/Vibe Kanban env-handling docs; exact $/token totals for N
parallel local agents; Devin stall-detection signals.

## Key citations

- vincentmvdm, MIDDLE_MANAGER.md gist [primary, active 2026-07] — https://gist.github.com/vincentmvdm/f4ad9c8977db5ceba3dfff980daf3c4d
- mattpocock/skills, skill files + PR #410 [primary, 2026-07] — https://github.com/mattpocock/skills ; /pull/410
- GitHub changelog, issue dependencies GA [primary, 2025-08-21] — https://github.blog/changelog/2025-08-21-dependencies-on-issues/
- gh CLI v2.94.0 sub-issues/dependencies [primary, 2026-06-10] — https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/
- Claude Code agent-teams / agents / worktrees docs [primary, v2.1.178+] — https://code.claude.com/docs/en/agent-teams
- Gas Town README + polecat-lifecycle-patrol design [primary, 2026-03] — https://github.com/gastownhall/gastown
- ghuntley.com/ralph + snarktank/ralph [primary/med, 2025-2026] — https://ghuntley.com/ralph/
- Sawyer Hood, "I Hired a Middle Manager" [primary, 2026-02-27] — https://sawyerhood.com/blog/hired-a-middle-manager
- GitHub Spec Kit clarify/spec templates [primary, 2026-07] — https://github.com/github/spec-kit
- MAST, arXiv 2503.13657 v3 [primary, 2025-10] — https://arxiv.org/abs/2503.13657
- ITBench×MAST [med-high, 2026-02-18] — https://huggingface.co/blog/ibm-research/itbenchandmast
- "All Smoke, No Alarm", arXiv 2606.18168 [primary, 2026-06-16] — https://arxiv.org/abs/2606.18168
- METR study + 2026 update [primary, 2025-07-10 / 2026-02-24] — https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/
- Anthropic, multi-agent research system [primary vendor, 2025-06] — https://www.anthropic.com/engineering/multi-agent-research-system
- Anthropic, C compiler with parallel Claudes [primary vendor, 2026-02-05] — https://www.anthropic.com/engineering/building-c-compiler
- Osmani, Code Agent Orchestra / 80% Problem [med, 2026-03-26 / 2026-01-28] — https://addyosmani.com/blog/code-agent-orchestra/
- Willison, parallel coding agent lifestyle [primary, 2025-10-05] — https://simonwillison.net/2025/Oct/5/parallel-coding-agents/
- Yegge, Future of Coding Agents [primary, 2026-01-05] — https://steve-yegge.medium.com/the-future-of-coding-agents-e9451a84207c
