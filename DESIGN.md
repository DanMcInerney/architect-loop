# DESIGN — architect-loop

**The design rationale for an autonomous software factory.** The orchestrator model
(the session you open — Claude Fable 5 or Codex) runs intake, writes the spec,
decomposes it into a GitHub issue plan, dispatches parallel fresh builder jobs
into worktrees, answers blockers, sends fresh judges against frozen checks, and
merges — with exactly one human step, spec approval. This document is the
"why", with citations; the skill files in `skills/architect/` are the "how";
[CONTEXT.md](CONTEXT.md) is the vocabulary.

**Standing evidence rule:** no feature ships without its evidence recorded in
DESIGN.md — a PR adding behavior without a DESIGN.md entry is incomplete by
definition.

This document describes the current system (v5.1). Superseded designs — the
v2 human-per-block slice loop, the v3 external loop driver, the v4
`docs/HANDOFF.md` repo diary — and their full evidence trails live in git
history and in [docs/spec/](docs/spec/architect-v5.md),
[docs/adr/](docs/adr/0001-in-session-loop-replaces-external-driver.md), and
[docs/research/](docs/research/autonomous-software-factory.md).

---

## 1. The problem

Single-agent coding sessions degrade in three predictable ways:

1. **Context rot** — performance falls as the window fills; Anthropic calls
   the context window "a finite attention budget with diminishing returns"
   ([Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)),
   degradation is measurable "at every increment, not just near the limit"
   ([Chroma](https://www.trychroma.com/research/context-rot)), and
   practitioners report a "dumb zone" past ~40% utilization
   ([HumanLayer ACE-FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents)).
2. **Self-grading** — the agent that wrote the code reports its own success.
   Benchmark studies found 47–74% of self-improvement runs showed proxy gains
   without real gains, with agents escalating from overt to obfuscated reward
   hacks ([OpenReview](https://openreview.net/forum?id=ikrQWGgxYg),
   [arXiv:2503.11926](https://arxiv.org/pdf/2503.11926)).
3. **Goalpost drift** — acceptance criteria written (or edited) after results
   exist always pass.

The surveyed sources converge on one shape — Anthropic's
[harness design post](https://www.anthropic.com/engineering/harness-design-long-running-apps),
[obra/superpowers](https://github.com/obra/superpowers), the
[Ralph loop](https://ghuntley.com/ralph/), and
[GitHub Spec Kit](https://github.com/github/spec-kit):

> **Separate planning context from execution context. Persist state outside
> the conversation. Dispatch fresh-context workers per task. Verify with an
> agent that didn't write the code.**

By 2026 the ecosystem name for the fully wired version is the
**"middle manager" pattern** — orchestrator-workers over issue/PR state
([vincentmvdm's gist](https://gist.github.com/vincentmvdm/f4ad9c8977db5ceba3dfff980daf3c4d),
[Sawyer Hood](https://sawyerhood.com/blog/hired-a-middle-manager)). Every
component of this design has a working precedent; the contribution here is
wiring them into two installable skills with the failure modes closed.

---

## 2. Roles and the two-model split

| Role | What it is | Owns |
|---|---|---|
| **Orchestrator** | the session the human opened | intake, spec, decomposition, check freeze, dispatch, blocker answers, merge decisions, digest |
| **Builder** | fresh worker agent, one per issue, own worktree | implementation and raw-evidence reporting only |
| **Judge** | fresh orchestrator-tier agent, read-only | frozen-check verdicts and diff-vs-intent |
| **Watchdog** | deterministic script per wave; "monitor" informally | mechanical stall evidence only — never kills, never decides |
| **Adversarial reviewer** | fresh reviewer, pre-freeze | the stress-test pass (called the *grill* in earlier runs) falsifies the decomposition before it's authorized |
| **Human** | you | spec approval, hard stops, taste |

Why the orchestrator does the design work and the builders only build:
[PEAR](https://arxiv.org/abs/2510.07505) measured that weak planners hurt
multi-agent performance more than weak executors, so judgment minutes go on
the strongest model and typing hours on the cheaper one. Community
measurements of orchestrator/worker splits report 58–74% lower cost than
running the top model end-to-end
([Fable 5 Orchestrator Playbook](https://www.developersdigest.tech/blog/fable-5-orchestrator-model-playbook)).

Why the judge is a *separate fresh context* at orchestrator tier rather than the
orchestrator itself: fresh-session review finds more real defects than
same-session self-review (F1 28.6% vs 24.6%, p=0.008,
[Cross-Context Review](https://arxiv.org/abs/2603.12123)), and Anthropic's
Fable 5 guidance states it directly: "Separate, fresh-context verifier
subagents tend to outperform self-critique"
([Prompting Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)).

Why cross-vendor when both CLIs are installed: builder and judge from
different labs reduces same-model review bias, which is measured at the
model-family level ([arXiv:2410.21819](https://arxiv.org/abs/2410.21819),
Panickssery et al. 2024). GPT-5.5 leads Terminal-Bench 2.0 (82.7%) for
hands-on terminal work while Anthropic positions Fable 5 for long-horizon
judgment ([Fable 5 announcement](https://www.anthropic.com/news/claude-fable-5-mythos-5)) —
the split lines up with what each model is best at.

---

## 3. GitHub issues are the coordination state

Through v4 the cross-session memory was a repo file, `docs/HANDOFF.md` — a
hand-pruned diary of decisions, verdicts, and docs debt. v5 retired it
(spec: [docs/spec/architect-v5.md](docs/spec/architect-v5.md)); **GitHub
issues are now the durable coordination log, and "not in the tracker =
didn't happen."** Git still carries what must version with the code: specs,
frozen checks, rulings files, job reports.

Why the move:

- **GitHub natively supports the whole graph.** Issue dependencies
  (blocked-by/blocking) went GA
  [2025-08-21](https://github.blog/changelog/2025-08-21-dependencies-on-issues/);
  sub-issues and issue types followed; `gh` CLI 2.94.0 added
  `--blocked-by`/`--parent`/`--blocking` flags explicitly "because coding
  agents rely on gh"
  ([changelog, 2026-06-10](https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/)).
  The scheduler reduces to "dispatch every issue whose blockers are closed,
  up to the job cap" — no custom state files or body-text conventions.
- **One diary file was the highest-contention artifact in the repo.** Every
  job's lifecycle wanted a row in it, which fought the disjoint-file-set
  rule that makes parallel jobs safe. Issues give each unit of work its own
  thread; comments are the append-only log.
- **The tracker is the human-visible dashboard.** PHASE-0 disagreements,
  blocker answers, verdicts, and the tracking issue digest are readable from GitHub
  without opening the repo — the audit trail is where humans already look.
- **Precedent for the delivery-channel split.** GitHub's own Copilot coding
  agent snapshots the issue at assignment and does not read comments posted
  after it starts. This design adopts the same reality: the issue thread is
  the *durable log*; a fresh spawn's context is the *delivery channel* for
  answers (see §4, blockers). Evidence:
  [docs/research/autonomous-software-factory.md](docs/research/autonomous-software-factory.md).

Issue mirror reality (v5.1): builders often cannot post to GitHub — the
Codex sandbox has no network and Claude subagents have a shell-strip watch
item (§7) — so `MIRROR: ORCHESTRATOR` is the normal mode: builders write
raw reports, the orchestrator mirrors status to the issue at event
boundaries it already occupies.

---

## 4. Design decisions

Each decision is enforced mechanically by the skill text, not left as
advice. Tags like D4/P2 refer to the numbered decisions in
[docs/spec/architect-v5.md](docs/spec/architect-v5.md),
[docs/spec/architect-v5.1.md](docs/spec/architect-v5.1.md), and the
loop-hardening research ([docs/research/loop-improvements.md](docs/research/loop-improvements.md)).

### Intake and spec approval

- **At most ~5 materiality-tested questions, in one batch (D3).** GitHub Spec
  Kit's `/clarify` is the template: each question must pass "would the answer
  materially change implementation or validation strategy?"; everything else
  becomes a recorded `## Assumptions` section the human can veto. This is the
  established middle path between maximal stress-testing and zero questions
  ([Spec Kit](https://github.com/github/spec-kit);
  [factory research](docs/research/autonomous-software-factory.md)).
- **Spec approval is the one human step (D4).** The human reviews one
  `docs/spec/<project>.md`, edits or vetoes assumptions, and approves.
  Approval authorizes the entire plan — after it, the human hears from
  the factory only through the tracking issue digest or a hard stop. Concentrating
  human attention at the spec is where misdesign is cheapest to fix
  ([PEAR](https://arxiv.org/abs/2510.07505): planner errors dominate).
- **Approval is explicit, durable, and fail-safe.** The two approval forms
  are in-session approval or an `APPROVE` comment on the tracking issue;
  an invocation can also pre-authorize a run only when the exact
  pre-authorization text is recorded verbatim. The evidence is the same shape
  across deployment systems and agent products: GitHub environments auto-fail
  unapproved runs after 30 days, Azure timeout-rejects approvals, OWASP
  fail-safe defaults ban inferred allow, and Copilot treats assignment itself
  as authorization. The 2026-07-03 human directive in
  [docs/spec/loop-tuning.md](docs/spec/loop-tuning.md) overrides the earlier
  park-and-poll product behavior: absent a human answer, wait about 5 minutes,
  rule with the orchestrator's best judgment, record the ruling for
  after-the-fact veto, and continue. Carve-out: irreversible or destructive
  choices resolve to the non-destructive path on silence; `docs/STOP` remains
  absolute
  ([factory-hardening evidence](docs/research/factory-hardening-evidence.md)).
- **Preflight has no fallback.** A GitHub remote, passing `gh auth status`,
  and `gh` ≥ 2.94.0 are hard preconditions; failing any of them fails
  loudly rather than degrading to a local tracker (no silent fallback, P1).
- **Backend canary before decomposition (v5.1 D1).** Every candidate builder
  backend runs one trivial task proving it has a working shell executor; a
  DEGRADED backend is substituted *before* the plan records tiers, with the
  evidence on the tracking issue. Motivated by 6/6 Claude subagent spawns losing shell
  tools in one day (§7, D12) — backend choice is an intake-time risk, not a
  mid-wave surprise.

### Decomposition

- **Vertical slices as issues, dispatched by ready issues (D5).** Each
  sub-issue is one tracer-bullet slice — "narrow but complete end-to-end,
  demoable on its own" — carrying what-to-build, acceptance criteria,
  boundaries, and native parent/blocked-by edges
  ([mattpocock/skills](https://github.com/mattpocock/skills) `/to-issues`;
  [Anthropic multi-agent](https://www.anthropic.com/engineering/multi-agent-research-system)).
  The parallel set is always the plan's ready issues, capped at five
  jobs plus one watchdog sweep.
  Tracking issue #43's 2026-07-03 DIGEST comment, reflected in
  [docs/spec/loop-tuning.md](docs/spec/loop-tuning.md) and
  [docs/jobs/status-scripts-rulings.md](docs/jobs/status-scripts-rulings.md),
  tightened run mechanics: judges dispatch concurrently for every DONE, the
  ready-issue frontier recomputes on every merge, independent bookkeeping
  batches into parallel calls, and merges, synthesis, and stress-testing stay
  serial.
- **Concurrently scheduled issues share nothing mutable.** Not files,
  migrations, lockfiles, generated artifacts, config, schemas, dev servers,
  or databases. Merge conflicts are the top reported multi-agent failure and
  the converged mitigation is disjoint touch sets + one worktree per agent +
  a small job cap
  ([Intility](https://engineering.intility.com/article/agent-teams-or-how-i-learned-to-stop-worrying-about-merge-conflicts-and-love-git-worktrees),
  [Geng & Neubig](https://huggingface.co/papers/2603.21489),
  [Cognition](https://cognition.ai/blog/multi-agents-working)). A merge
  conflict is therefore treated as a *decomposition* failure: kill the job
  and re-spec; never hand-resolve builder conflicts.
- **Producer issues carry interface contract blocks.** An issue whose surface
  another issue consumes must state names, parameters, return types, and
  behavior in its body; consumers reference the block. This is the
  delegation-contract rule — vague delegation causes duplication and
  misinterpretation
  ([Anthropic multi-agent](https://www.anthropic.com/engineering/multi-agent-research-system)) —
  applied between jobs, and it avoided merge conflicts in the dogfood runs
  (§7).
- **Design-quality doctrine (D9).** Structural and behavioral changes are
  separate issues with a blocking edge (structural checks prove existing
  behavior stays green); the oddity rule classifies resistance from reality
  before dispatch (local wart → patch; recurring variation → structural
  issue; three failed fixes → question the architecture); design-it-twice
  runs only for new load-bearing abstractions; testing seams are confirmed
  in the spec so jobs don't invent them mid-flight (TDD sourced from
  mattpocock's `tdd` skill; human ruling 2026-07-02).
- **Judged diffs target ≤ ~400 changed lines (P3).** Human review
  effectiveness falls off past ~200–400 LOC per pass, and long-context
  degradation compounds it ([Chroma](https://www.trychroma.com/research/context-rot));
  a spec that will exceed the target splits into more jobs or issues.

### Frozen checks and stress-testing

- **Checks freeze in git before results exist (R2 invariant, unchanged since
  v2).** Anthropic's three-agent harness negotiates the contract in shared
  files *before coding*, then freezes it
  ([Harness Design](https://www.anthropic.com/engineering/harness-design-long-running-apps));
  the reward-hacking literature adds the mechanical requirement to keep
  criteria out of the agent's editable blast radius. Checks live in
  `docs/checks/<issue-slug>.md`, freeze at one commit, and **any builder edit
  under `docs/checks/` is an automatic FAIL regardless of results**. Visible
  test-iteration loops measurably raise cheating (33%→38%,
  [ImpossibleBench](https://arxiv.org/abs/2510.20270)), so builders get no
  iterate-against-the-judge feedback channel.
- **Freeze → push → dispatch, then verify (v5.1 D2).** The factory branch
  `factory/<run>` is cut at spec approval; the freeze commit is pushed
  before any dispatch; after each spawn the orchestrator verifies the
  worktree HEAD equals the freeze commit and spot-checks one frozen file on
  disk. Motivated by a live finding: the first harness-created worktree had
  a fast-forwarded ref but stale files on disk
  ([docs/solutions/worktree-stale-snapshot.md](docs/solutions/worktree-stale-snapshot.md)).
- **One fresh independent adversarial pass attacks the whole decomposition (P2, widened by
  v5.1 D3).** Before the freeze, a read-only adversarial agent executes
  draft check commands against the current tree, attacks acceptance criteria
  for non-falsifiability and repo-name grep collisions, sweeps references to
  files the plan deletes or renames, and checks new artifact paths against
  `.gitignore`. Grounding: tool-grounded, fresh-context critique
  ([Cross-Context Review](https://arxiv.org/abs/2603.12123)); track record:
  real defects caught on every use so far — 5 (first use), 8, then 2
  blocking check defects (§7).

### Building

- **Fresh builder per issue; respawn over resume (D7).** The Ralph
  loop's core lesson is that the value is the always-fresh context
  ([ghuntley.com/ralph](https://ghuntley.com/ralph/)), and Anthropic treats
  fresh-context invocations as "equivalent to separate sessions"
  ([Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).
  When a job blocks or wedges, the orchestrator answers durably on the
  issue and spawns a *new* fresh job with the answer in its spawn context —
  it does not resume polluted context (a running builder never re-reads its
  own issue comments; see §3, Copilot precedent).
- **Builders never commit.** The orchestrator owns commits, merges, and
  issue closure. Codex `workspace-write` is the one backend with verified
  sandbox `.git` write protection; Claude builders use permission-deny rules
  plus post-flight branch/commit checks instead
  ([Codex sandboxing](https://developers.openai.com/codex/agent-approvals-security),
  [headless docs](https://code.claude.com/docs/en/headless)).
- **PHASE 0: disagreement is mandatory.** Before building, every job states
  its plan and every disagreement with the spec, citing real files — or what
  it checked before finding none. Silent compliance is a job defect.
  Rationale: prescriptive specs are followed literally by the builder-class
  models, so spec errors are only caught *before* execution; PHASE 0 caught
  a live orchestrator defect during the v5.1 run (§7). Every disagreement
  gets an explicit ACCEPT/REJECT/MODIFY ruling.
- **Raw evidence only; every status claim audited against tool output.**
  Builders report tables, numbers, and command output — no "promising", no
  verdicts. Anthropic's testing found status-audit instructions "nearly
  eliminated fabricated status reports"
  ([Prompting Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)).
- **No silent fallbacks, no unrequested backcompat (P1).** Success-shaped
  defaults can fake a passing check while the primary path is broken. Sources:
  OpenAI's [Codex Prompting Guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide)
  ("no silent failures");
  [claude-code#21027](https://github.com/anthropics/claude-code/issues/21027).
  The same rule binds the factory itself: missing preconditions and sandbox
  limits are recorded and routed to a hard stop, never worked around
  silently.
- **Dispatch carries the full contract.** Objective, output format, tool
  guidance, boundaries, rulings, and the frozen-check pointer travel in one
  self-contained block
  ([Anthropic multi-agent](https://www.anthropic.com/engineering/multi-agent-research-system);
  OpenAI prompting guidance: full spec up front in one well-specified turn).

### Judging and integration

#### Check-runner offload (2026-07-04)

The measured motivation was 135 mechanical `command → expected` items across
15 frozen check files, about 9 per file, with `tracker-adapter.md` 17-of-18
mechanical. Those commands were consuming frontier-priced judge turns on work
that required no judgment, while the useful judge work remained evidence
grading, checks-integrity review, and diff-vs-intent.

The check-runner is a deterministic script, not an LLM, because a script
cannot fabricate an exit code; an LLM runner is an unaudited junior judge. The
check-runner executes frozen RUN commands outside subagent sandboxes and
records raw evidence, while the fresh judge grades that evidence, performs
diff-vs-intent, and re-runs at least one RUN command as the spot-check honesty
guard. D12 consequence: shell-dependent checks no longer force cross-family
codex judges just to get a shell; cross-family review returns to a high-stakes
review choice rather than a workaround for stripped tools.

The RUN grammar came from the design-it-twice record in
[spec D1](docs/spec/judge-runner.md#d1-run-grammar-for-check-files-design-it-twice-record):
heuristic backtick-span parsing was rejected for structural false positives in
prose, fenced run blocks were rejected for authoring churn and for separating
the command from its inline expected outcome, and explicit `- RUN:` markers
were chosen.

#### Orchestrator mechanics offload (2026-07-04)

Run #62 measured the motivation: every dispatch cost about 4-5 orchestrator
calls (claim, worktree add, HEAD-vs-freeze verify, frozen-file spot-check, and
block assembly), every merge cost another 4+ calls (merge, push, worktree
remove, and branch delete), and the touch-set audit was still informal. These
are deterministic mechanics; the orchestrator needs to verify their facts, not
spend judgment context replaying them.

The pattern is now a typed-exit script family: watchdog → check-runner →
preflight/postflight. The watchdog reports liveness facts, the check-runner
records frozen RUN evidence, dispatch preflight creates and verifies the
worktree and frozen inputs, and merge postflight performs the touch-set audit,
merge, optional push, and cleanup. Each script emits typed evidence; the
orchestrator keeps judgment, blocker answers, and merge decisions.

The interface design-it-twice record rejected positional arguments and env vars
in favor of one config JSON path: positional args had six-plus parameters,
Windows quoting hazards, and no sibling consistency, while env vars hid state
and diverged between PowerShell 5.1 and bash. The full record lives in the
[orchestrator-scripts design section](docs/spec/orchestrator-scripts.md#design).

Run #68 was the first live use of the runner-fed judge path shipped in #62/PR
#67. Its first execution produced a D3-conformant evidence file but
quote-mangled every RUN command with quoted multi-word arguments because child
PowerShell `-Command` stripped quotes; the preserved defect evidence is
[docs/jobs/os-wiring-checkrun.md](docs/jobs/os-wiring-checkrun.md). The defect
was fixed in-run by the human-approved D5 amendment (#73), then validated
through the same path it repairs: the fixed runner executed its own frozen
acceptance checks and three subsequent evidence-consuming judgments (#73, #69,
#71), all grading committed evidence with spot-check re-runs. The judge
tree-audit guard also caught an orchestrator orphan-race snapshot commit
(judgment #2 on #71, INVALID), which shows the honesty guards catch defects in
both directions.

- **Nobody grades their own work.** The builder reports evidence; a fresh
  orchestrator-tier judge runs the frozen checks itself (builder claims are
  hearsay) and returns per-check **PASS / FAIL / INVALID** — INVALID meaning
  "not measured the way the check specifies", so unmeasured never equals
  passed ([Demystifying Evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)).
- **The judge also reads the diff against intent.** Check output alone is
  insufficient: METR found agent PRs that pass tests are mostly unmergeable
  as-is ([METR](https://metr.org/blog/2025-08-12-research-update-towards-reconciling-slowdown-with-time-horizons/)).
- **The orchestrator may not turn a judge FAIL into a merge.** Verdicts are
  posted as issue comments; an issue with no verdict comment is not built
  upon. Judgment context is pointer-only — frozen check file, spec, job
  report, rulings file — delivered by frozen templates the orchestrator may
  not decorate (template drift is how judge scope quietly widens).
- **Reviewers are calibrated.** "Flag only gaps that affect correctness, the
  stated requirements, or documented project invariants — cite file:line
  evidence. No style preferences." An uncalibrated reviewer always finds
  something, and that spirals into gold-plating.
- **High-stakes issues get cross-family review, direction chosen.** In the
  one available directional study, Claude reviewing Codex output helped
  while the reverse hurt; the skill prefers Claude-reviews-Codex and records
  the direction in the verdict comment
  ([cross-provider review](https://www.mindstudio.ai/blog/openai-codex-plugin-claude-code-cross-provider-review)).
- **Post-freeze rulings live in an append-only file (v5.1 D4).**
  `docs/jobs/<issue-slug>-rulings.md`, orchestrator-owned, committed before
  judge dispatch and mirrored to the issue — so judges read rulings from a
  file, not from thread prose, and post-freeze intent has a durable in-repo
  home.

### Failure, blockers, and stalls

- **BLOCKED is a completion event.** The job posts the exact blocker plus
  what it tried, and stops. The orchestrator answers on the issue and
  respawns fresh with the answer (D7).
- **Failure never moves the tier (human ruling, 2026-07-02).** Tier is set
  once at decomposition by config and dispatch rules. First FAIL: diagnose
  from judge evidence, fix the *input* — issue text, missing context,
  forbidden-pattern note — and respawn at the same tier. Second FAIL after
  an intervention: re-decompose or escalate. A failure is a spec, context,
  or architecture problem for the orchestrator, not a retry knob. (This
  superseded the earlier tier-up-over-retry heuristic, P6.)
- **No per-command kill ceilings (human ruling, 2026-07-02).** Long test
  suites are legitimate work. Liveness is output-file growth plus
  process-tree activity, never wall-clock alone; issues may carry duration
  *hints* that suppress false flags but are never enforced ceilings.
- **A repeated identical action is a stall signal (P4).** Even while output
  still grows. Evidence: the worst scaffold in
  [SWE-Marathon](https://arxiv.org/abs/2606.07682) repeated 32% of its tool
  calls and produced 63/83 timeouts; OpenHands ships the same detector.
- **The watchdog detects; the orchestrator rules (D6).** Detection is a
  deterministic script that reads file growth, process activity, and repeated
  command tails, then exits with typed evidence. Reasoning stays with the
  orchestrator. Gas Town draws the same boundary between "is session alive?"
  and "requires reasoning"; GitLab's one-hour no-output rule is the CI
  precedent; OpenHands ships code-level repeated-action thresholds and also
  documents the false positive that proves REPEAT is evidence, never an
  auto-kill. The local run-#30 LLM monitor measured 3 dispatches, 0 true
  positives, and 2 false positives, so the LLM monitor survives only as a
  fallback template
  ([factory-hardening evidence](docs/research/factory-hardening-evidence.md)).
  Done now means the report's last non-blank line starts with `STATUS:`; report
  existence alone produced twice-observed false `ALL_DONE` evidence in the
  run #36 respawn case and the run #43 incremental-write case recorded in
  [docs/spec/loop-tuning.md](docs/spec/loop-tuning.md).
- **Hard stops (D11).** the `docs/STOP` kill switch before any wave; irreversible actions;
  two consecutive KILLs; a blocker colliding with a recorded assumption
  (a spec-approval decision surfacing late); scope growth beyond the approved
  spec; unsatisfiable preflight. All of them stop the factory and ask the
  human.

### Model routing

- **Orchestrator, builders, judge, and watchdog are configurable roles, not brand
  names (D2).** Flat `key = value` lines in `.architect/config` (repo) then
  `~/.architect/config` (user); the alias table in `dispatch.md` is the
  single owned rot point mapping `codex/best`, `claude/best`, and tier-downs
  to current CLI flags, so model churn is reviewed in one place. The
  inherit-by-default shape follows the `opusplan` precedent and matching
  requests across aider/goose issue trackers.
- **Default builders are codex-first.** `codex/best` (gpt-5.5, xhigh) whenever
  the Codex CLI is on PATH; `claude/tier-down` (Sonnet, high) otherwise.
  Typing hours land on the flat-rate subscription with verified `.git`
  sandbox protection (§2 economics; PR #28).
- **xhigh for unattended builders.** Effort-curve data shows xhigh winning
  the metrics that matter unattended — semantic equivalence to the human PR
  (88% vs 69%) and review-pass rate (69% vs 38%) at ~2.2× the cost of high
  ([stet.sh](https://www.stet.sh/blog/gpt-55-codex-graphql-reasoning-curve));
  review-survival is the thing to buy for multi-hour runs. Dispatch rules
  (`when <task class> -> <tier>`) let recipe-like work route cheaper.
- **Optional cross-vendor gateways are documented as asymmetric and
  unverified.** Claude Code accepts Anthropic-compatible gateways via
  `ANTHROPIC_BASE_URL`; z.ai documents a GLM endpoint but the recipe is
  unverified here and Anthropic does not bless non-Claude routing; Codex
  needs a Responses-API translator ([docs.z.ai](https://docs.z.ai)).

### Run mechanics and memory

- **Everything lands on `factory/<run>`; main stays untouched until one
  closing PR.** The PR body closes the tracking issue and lists every shipped issue;
  each closed issue gets a back-link comment naming the PR.
- **Tracker-agnostic coordination uses the pinned TSV line protocol.** The
  community request recorded in
  [docs/spec/tracker-markdown.md](docs/spec/tracker-markdown.md) asks for
  projects "locally or on Gitlab" where GitHub issues are not feasible, and
  asks to keep the loop agnostic. The seam is the existing
  `TRACK`/`SUB`/`NOOPENRUN` TSV line protocol, not an abstract adapter layer:
  each tracker emits the same lines, and status rendering, phase derivation,
  and downstream logic stay single-implementation. File-based markdown was
  chosen for the second tracker because `docs/issues/` is git-tracked, has
  zero runtime dependencies, works fully local, and preserves the same audit
  trail through orchestrator-executed issue mutations. This follows the
  pinned-jq lesson in
  [docs/jobs/status-scripts-rulings.md](docs/jobs/status-scripts-rulings.md):
  duplicated graph logic failed repeatedly until one pinned emitter produced
  the line protocol consumed by both status scripts.
- **Docs debt batches into one dedicated job at the PR boundary (P7).**
  Product docs (README, DESIGN) are the highest-contention files in the
  repo and evidence rows need post-judgment information, so build jobs and
  the orchestrator never edit them mid-run; pointers accumulate and one
  docs job consumes them before the PR.
- **Conversational status display.** Decision: a mid-run status question runs
  the status tree script and prints that plain-text tree beside the prose
  answer. Why: Lazyagent's agent-tree precedent shows the right visual shape;
  Agent View does not list spawned subagents; `gh` 2.94 exposes the JSON tree
  fields (`parent`, `blockedBy`, state) needed for a read-only issue view; and
  chat surfaces do not render ANSI, so color follows `isatty` and `NO_COLOR`.
  The run scripts are invoked from the repo root or with `-RepoRoot`;
  live-watch was descoped by human ruling. Evidence:
  [docs/research/status-display-evidence.md](docs/research/status-display-evidence.md)
  and [docs/jobs/status-scripts-rulings.md](docs/jobs/status-scripts-rulings.md).
- **Nontrivial diagnoses are codified to `docs/solutions/<slug>.md`** and
  read back at grounding, so each run makes the next one easier. Measured
  basis: [docs/research/lesson-store-evidence.md](docs/research/lesson-store-evidence.md).

### The skill text itself

- **Thin, declarative, prunable.** The skill states invariants and
  interfaces, not micro-procedures: skill bodies stay in context all
  session ([Skills docs](https://code.claude.com/docs/en/skills)), skills
  written for prior models "can degrade output quality" on newer ones
  (Fable 5 guide), and the Claude Code team's own position is that better
  models obsolete scaffolds
  ([Latent Space](https://www.latent.space/p/harness-eng)). A standing
  maintenance rule says: re-read the skill each model generation and delete
  what models now do unprompted.
- **An 800-non-blank-line size guard is enforced by the validator (P5).**
  Models silently skip steps past an instruction-budget ceiling
  (HumanLayer/RPI; [docs/research/loop-improvements.md](docs/research/loop-improvements.md)).
  `tests/validate_skills.py` also freezes the load-bearing contracts: alias
  table, config grammar, judge templates, agent-definition constraints, and
  a guard that no retired handoff reference re-enters the skill text.

### The research skill

`/architect-research` is a separate skill because research-grade fan-out
runs ~15× chat-level tokens
([Anthropic multi-agent](https://www.anthropic.com/engineering/multi-agent-research-system)) —
it must be a deliberate act, never a side effect of building. Its design
decisions, from the 2026-06 evidence review and the r2 calibration pass
([docs/research/agent-pipeline-patterns.md](docs/research/agent-pipeline-patterns.md)):

- **Scout-first, topic-designed researchers — no fixed taxonomy.** All five
  surveyed production deep-research systems use adaptive planner-driven
  decomposition; dynamic beats static on GAIA
  ([OAgents](https://arxiv.org/abs/2506.15741) 47.88→51.52;
  [AOrchestra](https://arxiv.org/abs/2602.03786) +16.28% relative). A cheap
  scout (~10 searches) maps terminology, load-bearing systems, and fault
  lines; the orchestrator designs 3–6 researchers from that map, drawing
  source-class tactics from `tactics.md`. Perspective discovery was STORM's
  largest measured lever (unique references 99.83 vs 54.36,
  [STORM](https://arxiv.org/abs/2402.14207)). Fact-finds and comparisons
  skip the scout.
- **Hard budgets per researcher.** Researcher counts scale 1/2–4/4–6 by tier;
  tool-call budgets 3–10/10–15/15–25; ≤5 subjects per researcher (a
  researcher that fills its window dies without writing output); saturation
  stop; ≤2 gap rounds. Numbers from Anthropic's published orchestrator
  heuristics — without them, leads over- or under-delegate.
- **~2,500-token compact returns against a numbered source list (A1).**
  Human-amended from the proposed 1,500 after measuring this repo's own
  jobs at 2,000–3,600 tokens with citations; per-URL tag citations removed
  the double-citation waste.
- **Draft-as-state gap round (A2).** After wave one, the orchestrator
  sketches a skeleton draft; SUPPORTED/THIN/EMPTY section marks steer the
  gap round instead of re-chasing covered ground.
- **Verification is a separate pass against raw sources.** ≥2
  independent-origin sources per load-bearing claim; adversarial
  falsification searches; citations only from URLs fetched this session —
  even search-grounded agents fabricate
  [3–13% of URLs](https://arxiv.org/pdf/2604.03173).
- **Gathering parallelizes; synthesis never does.** One author writes the
  whole report (section-parallel writers produced disjoint reports;
  Anthropic's CitationAgent exists to stop summarizing-of-summaries). The
  committed report is the research handoff into the build loop's specs (A4).
- **Rejected:** extra coordination layers (58–515% measured overhead) and
  cache-alignment machinery (harness-owned; the preamble sits below
  OpenAI's 1024-token cache minimum).

---

## 5. Failure modes → mechanical mitigations

| Failure mode | Mitigation |
|---|---|
| Reward hacking / check tampering | Checks frozen in git pre-dispatch; `git diff` integrity check at judgment; tampering = automatic FAIL |
| Builder grades own work | Raw-evidence-only reports; fresh judge runs checks itself; cross-family review for high-stakes |
| Goalpost moving | Verbatim frozen check text; checks read-only after freeze; missing check = spec defect for the *next* issue |
| Scope creep | Explicit boundaries and out-of-scope per issue; silent additions = job failure; scope growth beyond spec = hard stop |
| Context rot | Orchestrator holds judgment only, never reads large diffs; fresh job per issue; tracker + git carry state |
| Merge conflicts between jobs | Disjoint mutable-state sets, ≤5 jobs, worktrees; conflict = decomposition failure, re-spec |
| Placeholder implementations | End-to-end executable check commands; "search before implementing; full implementations only" in the builder block |
| Silent fallbacks masking breakage | P1 ban; fail loudly; explicitly-specced resilience only |
| Fabricated status reports | Every status claim audited against a tool result, both sides |
| Check-passing but unmergeable work | Judge reads diff vs intent, not check output alone (METR) |
| Builder gaming visible checks | Frozen read-only checks; no iterate-against-judge loop (ImpossibleBench 33%→38%) |
| Stalled jobs | Watchdog script: growth + process + repeated-action checks; orchestrator rules on typed evidence; no kill ceilings |
| Runaway factory | `docs/STOP` kill switch; two-consecutive-KILL hard stop; assumption-collision hard stop; tracking issue digest as the human channel |
| Stale worktree snapshots | Freeze → push → dispatch ordering; post-spawn HEAD + file verification |
| Shell-stripped subagents | Backend canary at preflight; BLOCKED-with-evidence; recorded substitutions (§7) |
| Researcher context exhaustion | ≤5 subjects per researcher; compact returns; bisect dead researchers |
| Harness bloat / obsolescence | Thin declarative skill; 800-line guard; per-model-generation pruning review |

---

## 6. What this deliberately is not

- **Not same-session self-continuation.** Every unit of work gets a fresh
  context; the orchestrator sleeps between events instead of accumulating
  job output. Ralph-style same-session loops are the documented
  anti-pattern ([ghuntley.com/ralph](https://ghuntley.com/ralph/),
  [HumanLayer](https://www.humanlayer.dev/blog/brief-history-of-ralph)).
  There is also no external driver script — the loop is the orchestrator
  conversation itself
  ([ADR 0001](docs/adr/0001-in-session-loop-replaces-external-driver.md)).
- **Not a general-purpose orchestrator.** It is a build factory over GitHub
  issues plus a research harness; trivial work should be done directly —
  "don't run a $200 harness on a $9 task"
  ([Harness Design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
- **Not just Goal Mode.** Codex's Goal Mode loops plan→act→test→review
  internally; this design adds what it lacks — frozen external checks, fresh
  cross-model judgment, issue-plan coordination, and repo-resident evidence.
- **Not human-free.** Autonomy is bounded by spec approval at the front and
  hard stops throughout; kill/continue authority inside the run belongs to
  judges and hard-stop rules, and taste stays with the human.

---

## 7. Run-verified environment findings

Dated findings from live runs on this machine, kept because skill text
cites them. (Numbering note: D9/D11/D12 below are *environment findings*
from the v4–v5 evidence era; `SKILL.md`'s "D9" cites the design-quality
*decision* in [docs/spec/architect-v5.md](docs/spec/architect-v5.md). Both
namespaces are load-bearing in shipped text.)

- **D9 — desktop subagent Bash strip (2026-07-02).** Three human-run desktop
  canaries: Bash is stripped from subagent spawns by name, not position
  (padding falsified [claude-code#60237](https://github.com/anthropics/claude-code/issues/60237)'s
  first/last pattern), even fully synchronous (pre-permission-layer).
  Mitigation shipped: `PowerShell` as an interior second executor in both
  agent definitions with matching deny mirrors; the validator guards the
  padding. Related: [claude-code#18749](https://github.com/anthropics/claude-code/issues/18749).
- **D11 — CLI spawns can ignore `isolation: worktree` (2026-07-02).** A CLI
  spawn of an agent definition carrying the frontmatter ran unisolated in
  the orchestrator's checkout. Rule shipped: verify `git worktree list`
  after spawn; never run two Claude-backend jobs concurrently without
  verified separate worktrees.
- **D12 — intermittent, definition-asymmetric tool strip (2026-07-02).**
  Same session: a builder spawn kept both shell tools while two judge spawns
  lost both (and correctly returned INVALID). Cumulative that day: 6/6
  Claude subagent spawns shell-less — the basis for the preflight backend
  canary (v5.1 D1). Working mitigation: a cross-family Codex judge
  (workspace-write, tree audited untouched) for shell-dependent checks, plus
  a fresh headless `claude -p` session for checks the Codex sandbox cannot
  run — Git Bash dies with Win32 error 5 in that sandbox here
  ([docs/solutions/subagent-shell-strip-codex-fallback.md](docs/solutions/subagent-shell-strip-codex-fallback.md)).
- **D13 — Git Bash under the Codex Windows sandbox (2026-07-03).** This is
  no longer treated as a machine-local mystery: Git for Windows' MSYS2/Cygwin
  runtime creates per-user shared sections with `CreateFileMappingW`, while
  the Codex Windows sandbox runs commands under dedicated restricted users.
  The mismatch produces `CreateFileMapping ... Win32 error 5` at MSYS2
  startup. Native `git.exe` and PowerShell work in the sandbox, and POSIX
  Codex sandboxes are unaffected. Upstream status: [openai/codex#12000](https://github.com/openai/codex/issues/12000)
  and [openai/codex#21715](https://github.com/openai/codex/issues/21715).
  The local canary reproduced the MSYS2 failure for `bash.exe`, `grep.exe`,
  and `sed.exe` while native `git.exe` succeeded
  ([factory-hardening evidence](docs/research/factory-hardening-evidence.md);
  [solution note](docs/solutions/git-bash-msys-codex-sandbox.md)).
- **Codex 0.139 native `spawn_agent` round trip verified.** One thread
  spawned one child instructed to reply `PONG`; the parent surfaced
  `SPAWN_RESULT: PONG` after waiting — also the source of the note that the
  live event stream names the tool `wait`, not `wait_agent`.
- **Sandbox substitutions, recorded per check:** `uv` AppData cache denial →
  `UV_CACHE_DIR=.architect/tmp/uv-cache`
  ([docs/solutions/uv-cache-sandbox-redirect.md](docs/solutions/uv-cache-sandbox-redirect.md));
  out-of-workspace temp paths and `asyncio.create_subprocess_exec`-based
  tooling hang under workspace-write — prescribe in-workspace temp/cache
  paths and sequential check execution.
- **Stress-test catch record:** 5 draft-check defects (first use), 8 (second), 2
  blocking (third) — defects found on every use to date.
- **Dogfood runs.** v5 was built *by* the factory as a real issue plan (tracking issue
  #12, issues #13–#18): 1 judge FAIL, 3 respawns, all jobs fresh-judged.
  The v5.1 hardening run (tracking issue #20, issues #21–#25, on `factory/v5.1`)
  scored 0 judge FAILs and 0 respawns after the v5.1 decisions landed —
  canary preflight, freeze-push-dispatch, extended stress-test, rulings files.
  The preflight canary's first live use returned `CANARY: DEGRADED` for a
  Claude spawn and selected `codex/tier-down` for the whole run.

---

## 8. Sources

**Anthropic (official):**
[Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) ·
[Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) ·
[Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) ·
[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) ·
[Demystifying Evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) ·
[Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) ·
[Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) ·
[Skills](https://code.claude.com/docs/en/skills) ·
[Subagents](https://code.claude.com/docs/en/sub-agents) ·
[Headless mode](https://code.claude.com/docs/en/headless) ·
[Fable 5 announcement](https://www.anthropic.com/news/claude-fable-5-mythos-5) ·
[Prompting Claude Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)

**OpenAI / GitHub (official):**
[codex exec / non-interactive](https://developers.openai.com/codex/noninteractive) ·
[CLI reference](https://developers.openai.com/codex/cli/reference) ·
[Codex subagents](https://developers.openai.com/codex/subagents) ·
[Sandboxing & approvals](https://developers.openai.com/codex/agent-approvals-security) ·
[Codex prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide) ·
[Issue dependencies GA](https://github.blog/changelog/2025-08-21-dependencies-on-issues/) ·
[gh 2.94.0 sub-issues/dependencies](https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/) ·
[GitHub Spec Kit](https://github.com/github/spec-kit)

**Studies (architect-verified primary sources):**
[PEAR — weak planners hurt more than weak executors](https://arxiv.org/abs/2510.07505) ·
[Cross-Context Review — fresh-context judging wins](https://arxiv.org/abs/2603.12123) ·
[ImpossibleBench — test exploitation](https://arxiv.org/abs/2510.20270) ·
[METR — test-passing PRs mostly unmergeable](https://metr.org/blog/2025-08-12-research-update-towards-reconciling-slowdown-with-time-horizons/) ·
[SWE-Marathon — repeated-action stalls](https://arxiv.org/abs/2606.07682) ·
[Chroma — context rot](https://www.trychroma.com/research/context-rot) ·
[Geng & Neubig — worktree+manager topology](https://huggingface.co/papers/2603.21489) ·
[OAgents — dynamic beats static decomposition](https://arxiv.org/abs/2506.15741) ·
[AOrchestra — on-demand subagent construction](https://arxiv.org/abs/2602.03786) ·
[STORM — perspective-guided research](https://arxiv.org/abs/2402.14207) ·
[URL fabrication rates](https://arxiv.org/pdf/2604.03173) ·
[Reward hacking in self-improvement](https://openreview.net/forum?id=ikrQWGgxYg) ·
[Obfuscated reward hacking](https://arxiv.org/pdf/2503.11926) ·
[Self-preference bias in LLM judges](https://arxiv.org/abs/2410.21819)

**Community / practitioners:**
[vincentmvdm — middle-manager gist](https://gist.github.com/vincentmvdm/f4ad9c8977db5ceba3dfff980daf3c4d) ·
[Sawyer Hood — I Hired a Middle Manager](https://sawyerhood.com/blog/hired-a-middle-manager) ·
[mattpocock/skills](https://github.com/mattpocock/skills) ·
[obra/superpowers](https://github.com/obra/superpowers) ·
[Ralph Wiggum loop](https://ghuntley.com/ralph/) ·
[A Brief History of Ralph](https://www.humanlayer.dev/blog/brief-history-of-ralph) ·
[Advanced Context Engineering (HumanLayer)](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents) ·
[Cognition — multi-agents: what's working](https://cognition.ai/blog/multi-agents-working) ·
[Latent Space — Harness Engineering](https://www.latent.space/p/harness-eng) ·
[Fable 5 Orchestrator Playbook](https://www.developersdigest.tech/blog/fable-5-orchestrator-model-playbook) ·
[GPT-5.5 effort curve (stet.sh)](https://www.stet.sh/blog/gpt-55-codex-graphql-reasoning-curve) ·
[Intility — worktrees for parallel agents](https://engineering.intility.com/article/agent-teams-or-how-i-learned-to-stop-worrying-about-merge-conflicts-and-love-git-worktrees) ·
[Cross-provider review bridge](https://www.mindstudio.ai/blog/openai-codex-plugin-claude-code-cross-provider-review)
