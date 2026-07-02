# Architect v4: the loop is the conversation (grilled + approved 2026-07-02)

One orchestrator brain in a single interactive session — Claude Code or Codex,
CLI or desktop app — delegates building to cold-context subagents and gate
judgment to a cold-context judge subagent. No external driver scripts, no
sentinel protocol, no headless `claude -p` respawning, no PowerShell. The
repo (HANDOFF/gates/lanes/prd + git) stays the only memory.

Research basis: four parallel researcher lanes + two local capability
canaries, 2026-07-02. Load-bearing sources cited inline; full reports in the
session that authored this.

## 1. The problem with v3 (why refactor)

- The v3 loop is an **external driver** (`bin/architect-loop.ps1/.sh`) that
  respawns headless `claude -p "/architect"` sessions and reads a `LOOP:`
  sentinel from the handoff. It works (G7–G11 all PASSed live 2026-07-02) but:
  - It cannot work in the **desktop apps**: Desktop has no headless mode, no
    `--print`, no `dontAsk` permission mode, no per-session tool flags
    (code.claude.com/docs/en/desktop, "What's not available in Desktop").
  - The human experience was "open a new window and run /architect again to
    get past the gates" — the fresh-session judgment rule made the human do
    the driving, then the driver automated it with scripts the human doesn't
    want to own.
  - Headless brains need workspace-trust + allowlist bootstrap (v3 defect D7)
    — an entire class of setup friction that interactive sessions don't have.

## 2. What the evidence says (constraints the design must honor)

1. **Fresh context per unit of work is the invariant — not fresh OS process.**
   Anthropic's long-running-agent harness treats fresh-context agent
   invocations as equivalent to separate sessions
   (anthropic.com/engineering/effective-harnesses-for-long-running-agents).
   Claude Code subagents start genuinely cold: no parent conversation, no
   parent file reads (code.claude.com/docs/en/sub-agents, "fresh, isolated
   context window").
2. **Judge isolation must mean no inherited context.** Self-preference bias
   is empirically confirmed (arXiv 2410.21819 + 2026 follow-ups — already
   cited in DESIGN.md). Practitioner consensus: a cold-context subagent
   judge is sufficient for **objective, checkable, frozen criteria**; a
   different model/session is reserved for subjective architectural calls
   (Anthropic evaluator-optimizer scoping,
   anthropic.com/research/building-effective-agents).
3. **File-based memory + re-grounding ritual is the real persistence layer**;
   compaction alone is insufficient (Anthropic harness + context-engineering
   posts). Context quality clips well before the window fills (~147–152k
   observed; Chroma context-rot research) → compact proactively (~60%
   guidance, platform.claude.com/docs/en/build-with-claude/compaction) and
   keep the orchestrator thin by delegating heavy reading.
4. **Both harnesses now have native in-session delegation:**
   - Claude Code: Agent tool + custom agent definitions
     (`.claude/agents/*.md`: model, tools, disallowedTools, permissionMode,
     `isolation: worktree`, background) — works in CLI **and** Desktop;
     nested spawning to depth 5 since v2.1.172 (docs + local canary
     2026-07-02: nested spawn returned clean).
   - Codex: native subagents stable and default-on — `spawn_agent`,
     `send_input`, `resume_agent`, `wait_agent`, `close_agent`; max_threads 6,
     **max_depth 1** (developers.openai.com/codex/subagents). Known bug
     #20543: frame the child's task defensively ("Your task is: …").
     Codex also has native Skills (`.agents/skills/**/SKILL.md`,
     developers.openai.com/codex/skills), `/goal` loop mode (v0.128+), and
     `review_model` for build-vs-review model separation.
   - Windows: nested `codex exec` child processes break under the native
     sandbox (github.com/openai/codex/issues/18451, open) → native
     `spawn_agent` replaces `codex exec` children on the Codex side.
5. **Stop conditions: verification-driven primary, caps as backstop, human as
   ultimate breaker** (Codex long-horizon guidance; Ralph retrospective
   humanlayer.dev/blog/brief-history-of-ralph). Multi-agent fan-out costs
   ~15× tokens — don't fan out by default
   (anthropic.com/engineering/multi-agent-research-system).
6. **Cross-model review is asymmetric** (single study, tentative): Claude
   reviewing Codex output helped (71.6→89.7%); Codex reviewing Claude's hurt
   (91.4→82.8%). Keep cross-model review for high-stakes slices but treat
   the direction and the reviewer's calibration as part of the rule.

## 3. Design

### 3.1 Roles (all inside ONE session)

| Role | Who | Context | Never does |
|---|---|---|---|
| Orchestrator (brain) | the interactive session the human opened | grounded from repo docs; kept thin | build, judge gates |
| Builders (brawn) | cold-context subagents, 1–4 lanes, worktree-isolated | delegation block only | commit, touch gates, exceed file set |
| Judge | ONE cold-context subagent per slice judgment, brain-tier model, read-only | frozen gate file + repo access only — never the build conversation | edit anything |
| Cross-model reviewer | high-stakes slices only | diff + spec | style nits |

Answer to "should the brain spawn a second brain which launches the brawn?":
**No.** The orchestrator dispatches builders directly. Nesting is unavailable
on Codex (max_depth 1) and unnecessary on Claude. The second cold brain in
the system is the **judge**, and it must be downstream of the build, not
upstream.

### 3.2 The loop

```
ground (re-read HANDOFF + gates)          ← re-grounding ritual, every block
→ arbitrate open disagreements
→ [judge subagent] verdict on last slice  ← cold context, frozen gates only
→ rule KILL/CONTINUE, integrate lanes, commit, update HANDOFF
→ spec next slice, freeze gates, commit
→ dispatch builder subagents (background, worktrees)
→ keep working / idle; background completion re-invokes the session
→ next block (same conversation)
```

- Iterations are **turns in one conversation**, driven by background-task
  completion notifications (Claude: background subagents notify the session;
  Codex: `wait_agent`). Nothing blocks; nothing respawns; no new windows.
- The handoff still records everything ("not in the handoff = didn't
  happen"), so ANY new session — after a crash, the next morning, a
  different machine — picks up losslessly. Fresh-session-per-block remains
  the *fallback and refresh mechanism*, not the required transport.
- Context discipline (new skill rules): one slice per block; delegate heavy
  reading to subagents; compact proactively; when the session degrades,
  END IT and open a new one — the handoff makes this free.

### 3.3 Judgment integrity (replaces sentinel + fresh-window rule)

- Gates still freeze to `docs/gates/<slice>.md` before dispatch; still
  read-only; builder edits to them still auto-FAIL.
- The judge subagent receives ONLY: the gate file path, the freeze SHA, and
  "run each gate command, compare verbatim, return PASS/FAIL/INVALID + raw
  output; read the diff against the spec's intent." Cold context = it has
  never seen the spec discussion, the dispatch, or the builder chatter.
  Doctrine basis: finding 2 above — sufficient for objective frozen gates.
- The orchestrator may not overrule a judge FAIL into a merge; it may only
  re-spec (new slice) or KILL. High-stakes slices add the cross-model
  reviewer before merge.
- Anti-drift guard: the judge also confirms gates-file integrity
  (`git diff <freeze>..HEAD -- docs/gates/`) exactly as today.

### 3.4 Safety rails (in-session replacements for driver rails)

| v3 rail (driver) | v4 rail (in-session) |
|---|---|
| `--max-iters` | slice counter in HANDOFF; orchestrator stops after N slices per unattended stretch (default 10) and asks the human |
| `docs/STOP` kill file | kept — orchestrator checks before every dispatch (cheap, harness-neutral) |
| sentinel fail-safe | gone (no driver to protect); replaced by: no judgment recorded in HANDOFF = next session refuses to build on it |
| 5-nonzero-exit breaker | lane-level: a lane that fails twice re-specs or dies; never blind-retry |
| no-progress breaker | judge verdict is the progress signal; two consecutive KILLs → stop and ask the human |
| stall rescue ladder | background lane liveness: event/report files must grow; a silent lane past its ceiling is killed and its worktree discarded (unchanged from v3 doctrine, minus the driver) |
| unattended overnight | NOT our scripts: point at harness-native options (Claude `claude agents` background sessions / this harness's /loop; Codex Automations / `/goal`) in one short doc |

### 3.5 Per-harness delegation table (the only harness-specific text)

| | Claude Code (CLI + Desktop) | Codex (CLI + app) |
|---|---|---|
| Builder | Agent tool; shipped defs `.claude/agents/architect-builder.md` (disallowedTools: `Bash(git commit *)`, `Bash(git push *)`; `isolation: worktree`; background: true; model from alias table) | `spawn_agent` with defensive task framing; worktree created by orchestrator via git |
| Judge | Agent tool; shipped def `architect-judge.md` (read-only tools, brain-tier model) | fresh `spawn_agent`, read-only instruction |
| Parallelism | background subagents (permission prompts surface to main session) | max_threads 6, `wait_agent` |
| Review (high-stakes) | `codex review --base` when codex installed, else fresh same-CLI subagent + bias caveat (asymmetry note) | `/review` / `review_model`; claude reviewer when installed |
| Skill packaging | `skills/architect/` + `~/.claude/skills` (unchanged) | `.agents/skills/architect/SKILL.md` (new) — same text, installer copies |

### 3.6 What gets deleted

- `bin/architect-loop.ps1`, `bin/architect-loop.sh`, `tests/driver-canary.ps1`
  (git history preserves them), sentinel protocol in `loop.md`, sentinel
  contract C1, headless-brain material (trust/allowlist bootstrap for `-p`,
  env-strip guidance), installer driver copies.
- `loop.md` shrinks to: loop-block procedure, safety rails, unattended
  pointers. `dispatch.md` loses driver mechanics, keeps builder-block
  template + alias table + delegation table above.
- Keep: HANDOFF/gates/lanes/prd memory system, freeze-before-dispatch,
  PHASE 0 disagreements, disjoint-lane worktrees, graduated timeout
  ceilings, brain/brawn config + alias table, `docs/STOP`.

## 4. Slices

1. **v4-core** (Claude side, biggest): SKILL.md procedure rewrite
   (orchestrator/builder/judge blocks), new judge flow, shipped agent
   definitions (`.claude/agents/architect-builder.md`, `architect-judge.md`),
   `loop.md` rewrite, `dispatch.md` refactor, HANDOFF.template.md update
   (drop sentinel, add slice counter + judgment ledger), tests updated
   (sentinel tests → judgment-ledger + agent-def checks).
2. **v4-codex**: `.agents/skills/architect/SKILL.md` packaging + installer;
   codex delegation guidance (spawn_agent framing, /goal, review_model);
   verify against live codex 0.14x (spawn_agent round-trip canary).
3. **v4-cleanup + evidence**: delete drivers/canary/sentinel material;
   DESIGN.md v4 evidence section (sources above) per the standing rule;
   README usage rewrite ("open the app, type /architect — that's the loop").

Canaries before merge: (a) Claude CLI toy-slice loop fully in-session
(build → judge → integrate, no new window); (b) same flow driven from the
**desktop app by the human** (we cannot automate Desktop); (c) codex CLI
spawn_agent builder + judge round-trip; (d) context-discipline check: a
3-slice run stays under the proactive-compaction line or hands off cleanly.

## 5. Stolen patterns (second research pass, 2026-07-02: PaulSolt workflow + kunchenguid/firstmate)

Sources: x.com/PaulSolt/status/2071945658492170259 (recovered via browser;
"Codex can have a thread manage other threads… heartbeats… /goal on work
threads… push work forward until it's ready to merge") and
github.com/kunchenguid/firstmate (README, AGENTS.md, docs/architecture.md,
crew-dispatch.json — all VERIFIED by researcher fetch).

**Adopted into v4 (all in-harness, desktop-safe):**

1. **Heartbeats as stall fallback** (PaulSolt / Codex Automations). v4's
   primary continuation signal is background-completion notification; add a
   heartbeat: when a lane is dispatched, the orchestrator sets a periodic
   check-in cadence (Codex: Automations/heartbeat; Claude Code: the
   harness's scheduled-wakeup/loop facility where present, else check on
   next user turn). A lane silent past its ceiling at a heartbeat = the v3
   stall doctrine (kill child, discard lane), no driver needed. This
   replaces v3's WAIT-tick liveness sweep 1:1.
2. **Completion-forcing worker loops** (PaulSolt: `/goal` on work threads).
   Codex lanes dispatch under `/goal` semantics — persistent objective =
   "your lane's gates pass" — so workers don't stop halfway. Claude lanes
   keep the builder block's persist-until-handled clause (same effect).
3. **Merge-readiness includes review findings** (PaulSolt: agents "address
   PR issues"). Lane definition of done gains: address the review gate's
   findings before reporting COMPLETE, when a review gate applies.
4. **Ship vs scout lane shapes** (firstmate). Formalize two lane types in
   the spec template: `ship` (code change, full gates) and `scout`
   (investigate/research, writes report only, may not touch code). We
   already do this informally (research fan-out, evidence lanes); naming it
   in the template removes per-slice boilerplate.
5. **Natural-language dispatch rules** (firstmate `crew-dispatch.json`).
   Extend `.architect/config` with optional `when → cli/model:effort — why`
   rules the orchestrator reads at spec time ("trivial mechanical edit →
   claude/haiku:low"; "big ambiguous refactor → codex/gpt-5.5:high").
   Defaults unchanged; this is the brain-plans/brawn-codes principle made
   configurable per task class instead of per slice.
6. **Reconcile-on-ground** (firstmate: "kill the first mate session anytime;
   the next one reconciles and carries on"). v4 grounding gains an explicit
   reconciliation step: compare handoff claims against actual git/worktree/
   lane-report state; stale or dead lanes are detected at ground, not
   discovered mid-block. This is what made firstmate restart-proof, and it
   hardens our crash-recovery story.
7. **Escalation digest** (firstmate `/afk`). When multiple lanes resolve
   while the human is away, the orchestrator writes ONE digest entry to the
   handoff instead of interleaved noise; ask-the-human items are batched.
8. **Stuck-lane judgment note** (firstmate recovery skill): "a low context
   reading is not wedging; harnesses auto-compact and keep going" — folded
   into the rescue guidance verbatim-in-substance.

**Explicitly rejected (terminal-only or fragile — the exact class v4 removes):**
tmux pane spawning + keystroke injection (`fm-send.sh`), busy-detection by
regex-scraping pane text per harness, external bash watcher daemons
(`fm-watch.sh`/`fm-supervise-daemon.sh`), wake-queue files. firstmate's
researcher verdict: "Nothing here is 'pure in-harness.'" Its *judgment
patterns* transfer; its *transport* is the anti-goal.

**Counterpoint logged:** Steinberger ("Just Talk To It", credited by Solt)
rejects a formal cheap/expensive split and kicks hard questions to a stronger
model ad hoc. v4 keeps tiering as the default (F10 + economics evidence) but
the dispatch-rules table (item 5) makes per-task overrides one line.

## 6. Grill decisions (human, 2026-07-02 — all binding)

| # | Decision | Ruling |
|---|----------|--------|
| 1 | Judge tier/config | Judge = brain tier, NO new config key ("the brain with fresh eyes"); config stays brain/brawn |
| 2 | v3 machinery | Delete everything outright — drivers, driver canary, sentinel protocol, headless-brain setup docs; git history is the attic (ADR 0001) |
| 3 | Unattended story | Pointer-only to harness-native mechanisms (Codex Automations//goal; Claude Code native background/scheduling); zero infra of ours |
| 4 | Dispatch rules | Adopt, optional with strong defaults — absent file changes nothing; no starter file shipped |
| 5 | Desktop canary | HUMAN-RUN frozen merge gate for v4-core: one toy slice driven from the Claude Code desktop app by the human |
| 6 | PR #8 sequencing | Merge PR #8 (v3) first; v4 slices land on top as normal reviewed diffs |

Architect-resolved (from repo + evidence, not asked): judge delegation is a
frozen template (gate path + freeze SHA + branch only — orchestrator cannot
editorialize to the judge); cross-model review keeps the high-stakes-only
trigger plus the direction-asymmetry note; one skill, loop-is-default
(scale-to-task rule already exempts trivial fixes); Codex packaging is
installer-copied single-source skill text.

Companion docs: `CONTEXT.md` (ubiquitous language incl. retired terms),
`docs/adr/0001-in-session-loop-replaces-external-driver.md`.
