> PRD for slice `v3-loop`. Committed verbatim (header added) from
> `C:\tmp\architect-skill-loop-plan.md` (source of truth, 2026-07-01/02,
> adversarially reviewed, evidence-closed). This plan WINS over
> `v3-loop-stall-prevention.md` wherever they conflict — notably §4.4's
> graduated per-command timeout ceilings replace the blanket 600s cap.

# Architect skill v3 plan: stall prevention + a real loop + configurable brain/brawn

Target: `C:\Users\danhm\tools\architect-loop` (source repo for
`~/.claude/skills/architect/`). Goal: frictionless delivery of the workflow.
Every decision below is rooted in cited evidence, and §4.8 makes DESIGN.md
carry that evidence for every feature going forward. Three parts:

- **Part A** — the builder-stall prevention plan
  (`C:\tmp\architect-skill-stall-prevention-plan.md`, 2026-07-01), adopted
  with one amendment (the blanket 600s command cap becomes a graduated
  timeout policy — human review 2026-07-02, see §4.4); restated here only
  where other parts touch it.
- **Part B** — replace "open a new tab and run /architect" with an actual
  loop: each work block runs in a fresh agent session started
  automatically, on any OS, under either supported harness.
- **Part C** — configurable BRAIN (judgment model; today hardcoded-in-prose
  as Claude Fable) and BRAWN (builder CLI+model; today hardcoded as
  `codex exec -m gpt-5.5` xhigh): set once, honored everywhere, with
  zero-config defaults that lean UX over framework.

**Scope (human decision 2026-07-02): the skill supports Claude Code and
Codex only.** The F13 matrix supports the cut: of five surveyed CLIs, two
(gemini, pi) cannot safely hold the builder role unattended and one (agy)
is unverifiable from docs — multi-harness support bought complexity, not
capability. The pi/opencode/gemini/antigravity findings stay below as
evidence and as the recorded rationale; revisiting is a DESIGN.md note,
not scaffolding in the skill.

Research basis: eleven research lanes across 2026-07-01/02 — five Opus
(session continuation, cross-platform spawning, loop architecture,
brain-selection mechanics, UX pareto frontier), two Codex xhigh (builder
capability matrix, config persistence), two Opus fact-finds (codex
tier-down economics, pi/Antigravity tiers), two Sonnet adversarial-gap
lanes (claude headless permission semantics; unattended-flag matrix for
codex/gemini/opencode/agy/pi in brain and builder roles). Load-bearing
findings F1–F13 below; everything else follows from them. An adversarial
review pass (2026-07-02) fixed: circuit-breaker false-fire on long builds,
cheap-model-judging hole, codex-brain `.git` write conflict, first-run
preflight block, and trimmed the driver flag set.

---

## 1. Research findings that constrain the design

### Loop findings (Part B)

**F1 — The fresh-session invariant is externally validated; in-harness
self-continuation is the documented anti-pattern.** Anthropic's own Ralph
plugin re-feeds the prompt into the *same* session via a stop hook; community
analysis documents context accumulating into the "dumb zone" by iteration
3–4, "fundamentally undermining the reason Ralph works"
(aihero.dev/why-the-anthropic-ralph-plugin-sucks; ghuntley.com/ralph;
humanlayer.dev/blog/brief-history-of-ralph). Claude Code's `/loop`,
`--continue`, `--resume`, `--fork-session` all reuse conversation context
(code.claude.com/docs/en/cli-reference) — all rejected.

**F2 — Every production agent loop found uses an OUTER driver script the
human starts once**, re-invoking the CLI one-shot per iteration:
AnandChowdhary/continuous-claude ("each iteration runs in a fresh CLI
session"), frankbria/ralph-claude-code, Maleick/claude-autoresearch. A new
OS process per iteration makes fresh context *structural*. Chained spawning
(each session launches the next, exits) works but loses crash recovery, the
central iteration cap, and observability — degraded fallback only.

**F3 — Spawning a visible GUI terminal from inside an agent session is the
highest-friction path; no verified success report on any OS.** Codex's
sandbox puts children under a restricted token + Job Object on a private
desktop — invisible and killed at teardown
(developers.openai.com/codex/concepts/sandboxing; codex.danielvaughan.com
Windows-sandbox deep-dive). macOS GUI paths hit a *blocking* first-run TCC
dialog. Headless Linux has no display. Reliable primitive: **detached
process + logfile** (`Start-Process` survives parent per MS Learn;
`tmux new-session -d` / `setsid` on POSIX). Consequence: the loop does not
open a window per block — **the driver's terminal is the persistent visible
surface**; every iteration streams into it.

**F4 — Claude Code has a first-party chaining primitive:**
`claude --bg "/architect"` starts a fresh-context background session hosted
by a separate per-user supervisor that survives the launcher's exit
(code.claude.com/docs/en/agent-view). Skills work in headless prompts unless
`--bare` (code.claude.com/docs/en/headless). Verified gotchas: (a)
nested-launch guard + ~50–60% hang if `CLAUDECODE` env is inherited — fix is
`env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT` via an external script, never
inline (issue #26190); (b) background `bypassPermissions` requires one
interactive acceptance of `--dangerously-skip-permissions` per machine;
(c) hooks docs say "do not spawn Claude Code sessions from within hooks" —
hook chaining rejected; (d) the June 2026 Agent-SDK-credits billing split is
**paused** — `claude -p` currently draws normal subscription quota
(support.claude.com/en/articles/15036540); recheck before relying on it.

**F5 — One SKILL.md is genuinely cross-harness, and a driver can detect its
harness.** obra/superpowers ships identical skills to Claude Code, Codex,
pi, opencode, Cursor, Copilot CLI, etc. Headless one-shot invocation exists
on every major CLI. `CLAUDECODE=1` is documented for detection; other
harnesses via a user-set `AGENT_CMD`. Production rails to copy: hard
iteration cap, circuit breaker (3 no-progress OR 5 identical errors),
explicit machine-readable exit signal, kill-switch file.

### Model-configuration findings (Part C)

**F6 — The brain binds at launch; a running skill can neither reliably
detect nor change its own model.** No harness exposes a live-model signal to
subprocesses (Claude Code's `ANTHROPIC_MODEL` goes stale after `/model`;
open feature request #37817; nothing on codex/gemini/pi/opencode).
Mid-session `/model` commands are interactive-only. Therefore **brain
selection lives in the launch command** — the loop driver in loop mode, the
human's launcher interactively. The skill's job is detect (`CLAUDECODE`,
`CODEX_HOME`) + advise; it never self-switches.

**F7 — Cross-vendor model mixing is real but asymmetric.** Claude Code runs
third-party Anthropic-API-compatible models via
`ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN` — z.ai officially markets a GLM
endpoint for Claude Code (docs.z.ai; GLM-5.2 specifically unverified in
primary sources; Anthropic documents the mechanism for gateways and states
it does not support routing to non-Claude models — gray zone, works but
unblessed; set `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`). Codex accepts
only Responses-API providers (`wire_api = "responses"`; raw Anthropic or
chat-completions endpoints need a translating gateway, e.g. LiteLLM).
opencode is the most model-agnostic (75+ providers via models.dev). pi is
flexible via `~/.pi/agent/models.json` and has verified headless one-shot
(`pi -p` + `--model <pattern>:<effort>`), defaulting to Claude Sonnet.
Antigravity — earlier "GUI-only" finding REVISED 2026-07-02: since I/O
2026 it ships an official `agy` CLI with headless `agy -p`, a `--model`
flag, `agy models`, and OS-native sandbox permission modes
(codelabs.developers.google.com/antigravity-cli-hands-on) — it qualifies
for the driver and as a builder backend; only the IDE's per-agent model
picker remains GUI-only. So the user's "GLM 5.2 brain + Opus 4.8 brawn
while sitting in codex" scenario IS achievable — but by launching the
brain session under Claude Code+z.ai env or opencode (driver-level), not
from inside Codex.

**F8 — Builder backends beyond codex are viable, but only codex has
verified `.git` protection.** `claude -p` has everything else needed
(`--model`, `--effort low..xhigh|max`, `--json-schema`,
`--output-format stream-json`, `--worktree`); opencode probable
(`opencode run --model provider/model`, flag unverified); gemini partial;
pi headless unverified (RPC mode only). Sandbox `.git` write-protection —
load-bearing for "builders never commit" — is verified **only** for Codex
workspace-write (developers.openai.com/codex/agent-approvals-security).
Non-codex brawn requires a compensating post-flight control (§3C.6).

**F9 — Precedent converges on inherit-by-default + one named split +
graceful degradation, and against config matrices.** aider auto-derives
editor/weak models from `--model` (the loved part; every config complaint
traces to knobs beyond it — issues #3087/#3085/#3287/#3543). Claude Code's
`opusplan` encodes an entire planner/executor split in one alias and
degrades with named-substitution warnings ("stays on Sonnet in plan mode if
Opus is excluded"). opencode subagents inherit the invoker's model. Roo Code
= sticky model per mode. goose maintainers are actively consolidating their
lead/worker/oracle env-var matrix (block/goose#4036) — the cautionary tale.
Tier aliases beat pinned IDs (Claude Code aliases "update over time";
pinned slugs rot — dispatch.md's own warning about silent fallback).

**F10 — Same-family judge bias is quantified and operates at the family
level, so cross-vendor judgment stays the default — but soft.**
Self-preference is largely a familiarity/low-perplexity effect
(arXiv:2410.21819, NeurIPS 2024 SafeGenAI), correlated with
self-recognition (Panickssery et al. 2024); "preference leakage" extends it
to related models; 2026 mitigation consensus is multi-family ensemble
judging (~3× cost — heavier than this loop's single-brain design). A single
cross-family judge reduces but does not eliminate bias → **warn-and-
override when brain family == brawn family, not a hard block.**

**F11 — No prior art exists for a cross-harness skill config file** (codex
xhigh survey of superpowers, vercel-labs/skills, claude-skills collections)
— we define the convention. Borrow proven precedence: aider
(home → repo root → cwd, later wins), git (system → global → local),
opencode (global → project). Audit-trail precedent: superpowers now
requires every subagent dispatch to state its model.

**F12 — Claude Code headless permission semantics (S1, verified
2026-07-02).** In `-p` mode an un-preauthorized tool call **aborts the
run** (official: "the run aborts when one is attempted",
code.claude.com/docs/en/headless) — except under `--permission-mode
dontAsk`, which hard-denies and continues (the designed CI mode).
`acceptEdits` covers only file edits + a fixed 7-command filesystem Bash
set — NOT gate commands, NOT git (the plan's earlier acceptEdits line
would have broken both roles). `--allowedTools "Bash(git commit:*)" ...`
works in `-p`, and project `.claude/settings.json` permissions.allow
rules apply to `-p` runs — a repo can be allowlisted once.
`--dangerously-skip-permissions` refuses to run as root, must never be
combined with `--permission-mode` (silent-override bug #17544), and
Anthropic scopes it to isolated containers/VMs. Production loops split:
ralph-claude-code uses default-deny + settings.local.json allowlist (and
surfaces permission_denials from the JSON output); continuous-claude uses
skip-permissions but only on ephemeral CI runners; Anthropic's own
claude-code-action never uses it. Bonus: `dontAsk` + an allowlist that
omits `git commit` + explicit `--disallowedTools "Bash(git commit *)"
"Bash(git push *)"` gives the claude builder a REAL no-commit guarantee —
prevention, upgrading F8's detection-only compensating control.

**F13 — Unattended-flag matrix for codex/gemini/opencode/agy/pi (S2,
verified 2026-07-02).** `codex exec` has no approval flow at all — it
executes under the configured sandbox; `danger-full-access` grants `.git`
write + network (architect role works), and `workspace-write`'s `.git`
read-only protection is **kernel/sandbox-enforced, the only hard builder
boundary among the five CLIs** — no config toggle unprotects `.git` short
of full access (developers.openai.com/codex/agent-approvals-security).
(S2 suggested `--ask-for-approval never`; dispatch.md's live 0.139
verification says exec rejects that flag — both agree no approval flow
exists, so it's omitted; re-canary at implementation.) **opencode**:
`opencode run --auto` + pattern denies (`bash: {"git commit *": "deny",
"git push *": "deny", "git merge *": "deny", "*": "allow"}`) is a
workable policy-level builder; deny rules survive `--auto`
(opencode.ai/docs/permissions). **Gemini**: `--yolo` works for the
architect role, but the builder role is NOT SAFELY POSSIBLE natively —
no git-aware sandbox, command exclusion documented as bypassable with two
open bugs (#17728 blocking failure, #20469 policy ignored in
non-interactive auto_edit). **pi**: no tool-permission system by design
("No permission popups"; `-a/--approve` is project-trust only) — fine as
an architect, NOT SAFELY POSSIBLE as an unattended builder without
external containerization (community `pi-less-yolo` Docker pattern).
**agy**: primary docs unfetchable, three secondary sources conflict on
flag syntax — unverified until a live `agy --help` canary.
**Consequence: the safe-builder set is {codex, claude, opencode}.**

---

## 2. Design decisions

**Loop (Part B): an outer driver script (`architect-loop`) the human starts
once.** It loops: invoke the harness one-shot with `/architect` → wait for
exit → read a machine-readable sentinel from the handoff → continue /
sleep-and-retry / stop. Fresh context per block is structural (F1/F2), it
works under both supported harnesses (F5), and its sleep-relaunch cycle IS
the scheduled liveness check stall-plan §3.4 demanded. Fallback: chained detached spawn
(`claude --bg` with env-strip on Claude Code; detached launcher elsewhere) —
documented as degraded. Last resort: today's manual handoff. `/architect`
alone keeps one-work-block behavior; the loop is opt-in.

**Models (Part C): zero-config inherit + auto-pair, with ONE optional
two-key config file as the only escape hatch.** Chosen over both "no
config" (no lever for the GLM-brain user) and any per-role
effort/provider matrix (F9's documented failure mode). Specifically:

- **Brain defaults to the session you're already in** — the model AND
  effort you launched /architect with (opencode/goose inherit precedent,
  F9): in Claude Code, the current Claude model; in Codex, the current
  GPT. In loop mode the driver's launch command selects it (F6).
- **Brawn defaults to same family, one step down** (human decision
  2026-07-02, opusplan precedent F9): Claude Code brain → `claude/sonnet`
  (Sonnet 5); Codex brain → `gpt-5.5` at effort `high` (effort-down beats
  model-down — see 3C.3 evidence). Zero extra dependencies — works with a
  single CLI installed. Tradeoff owned explicitly: builder hours land on
  the same subscription as judgment, and judge/builder share a model
  family.
- **The cross-family evidence (F10) is applied at the review gate, not the
  build default:** when the *other* CLI of the pair is on PATH (probed by
  the existing `--version` canary), the step-2 adversarial review for
  high-stakes slices runs on it automatically, and grounding prints a
  one-line advisory that a cross-family brawn is available and how to
  switch. Same-family bias is a judging phenomenon — spending the
  diversity budget on review keeps most of the mitigation at zero setup
  cost.
- **One config file, two keys** (`brain`, `brawn`) overrides either role,
  set once, honored by every session, every harness, every repo (F11
  precedence). Everything else — effort, lane counts, review depth —
  remains architect judgment per slice, NOT config (F9: effort knobs are
  the aider-complaint class; the skill already encodes effort policy as a
  per-slice judgment call).
- **Degrade, never fail** (F9 opusplan policy): a configured brawn that is
  missing at preflight → fall back to the tier-down default with a named
  requested-vs-substituted warning; no cross-family CLI anywhere → review
  gate falls back to a fresh same-CLI context with a logged caveat naming
  the F10 bias.

---

## 3. Contracts (the specs)

### 3B. The loop contract (Part B)

**3B.1 Sentinel protocol** — `docs/HANDOFF.md` TL;DR gains one required
line, written by the architect session as its **last act** every block:

```
LOOP: CONTINUE                       # block done; next block may start now
LOOP: WAIT 20 (2 lanes in flight)    # builders running; re-invoke in ~20 min
LOOP: STOP (<reason>)                # human needed / done / stop rule hit
```

Fail-safe parsing: sentinel missing, unparseable, or file untouched →
STOP. Runaway protection never depends on the model remembering to write
STOP. `LOOP: STOP` is mandatory on any hard-rule-8 stop condition, on goal
completion, and on arbitration that needs the human; the reason is the
message to the human. Sentinel updates are working-tree-only — they ride
along with the session's natural commits (freeze, integrate) rather than
forcing a commit per WAIT tick; the driver reads the file, not git.

**3B.2 Session types — the WAIT fast path.** A loop-started session grounds
as today, with one addition: if the handoff shows lanes in flight, run the
liveness fast path — check each lane's `--json` file growth, run Part A's
rescue ladder if stalled, write `LOOP: WAIT <interval>`, exit. After a
WAIT, the driver automatically relaunches on the tier-down brain (no flag
— one less knob), and **WAIT sessions never judge**: if a fast-path
session finds all lanes complete, it writes `LOOP: CONTINUE` and exits;
the next iteration — full brain — does the judging. This closes the hole
where the driver, unable to know mid-sleep that builders finished, would
otherwise seat a cheap model in the judgment chair. Cost: one extra cheap
iteration per slice. This mechanizes stall-plan §3.4: worst-case stall
detection = one WAIT interval.

**3B.3 Driver safety rails** (F5 production evidence): `--max-iters N`
(default 50 — WAIT iterations count, and a 6-hour build at 20-min WAITs
alone is ~18); circuit breaker — **progress = a new commit OR a sentinel
change OR any lane event-file growth** (a healthy hour-long build produces
identical WAIT sentinels and zero commits; lane growth is what
distinguishes it from a wedged loop): 3 consecutive no-progress iterations
or 5 consecutive nonzero exits → STOP with diagnostics; kill switch
`docs/STOP` (checked before every invocation; architect sessions treat
its presence as STOP too); per-iteration log
`.architect/loop/<n>-<timestamp>.log` + one `loop.log` index line each;
optional `--max-hours`. Never bound sessions with `--max-turns`
(hard-errors mid-work, F4 research).

**3B.4 Harness invocation (inside the driver).** Two harnesses, chosen by
the resolved `brain` string's CLI part (default: whichever of
claude/codex is on PATH, claude first). Claude Code:
`claude -p "/architect" --model <brain> --permission-mode dontAsk` with
the repo's allowlist living in `.claude/settings.json` permissions.allow
(F12: applies to `-p`; dontAsk denies-and-continues instead of aborting).
The first architect session in a repo writes that allowlist — Read/Edit/
Write, the repo's gate commands, and `Bash(git status/diff/log/add/
commit/merge:*)` — as part of handoff bootstrap and records it in the
Decisions log, so the human sees exactly what standing permissions the
loop granted itself. Env-strip `CLAUDECODE`/`CLAUDE_CODE_ENTRYPOINT` when
the driver was started from inside a session; never `--bare`. Codex:
`codex exec -C <repo> --sandbox danger-full-access - < prompt.md` — NOT
workspace-write: the architect commits gate freezes and merges lanes, and
workspace-write makes `.git` read-only (F8); full access is the price of
the brain role under codex — F13 verified: exec has no approval flow, and
no middle ground exists between workspace-write and full access (prompt
inlines the skill text; `$skill` invocation in exec is unverified). Which harness the
driver launches is decided by the resolved `brain` string's CLI part —
no separate harness flag. `--permissions bypass` opts into
`--dangerously-skip-permissions` — container/VM use only per Anthropic,
and never combined with `--permission-mode` (bug #17544); requires the
one-time interactive acceptance (F4b).

### 3C. The model-configuration contract (Part C)

**3C.1 Role strings.** `brain` and `brawn` are `<cli>/<model-spec>`
strings where `<cli>` ∈ {claude, codex}: `codex/best`, `claude/opus`,
`claude/sonnet`. Optional `:effort` suffix pins effort
(`codex/gpt-5.5:xhigh`); otherwise the alias table's effort applies.
`<model-spec>` is passed to the CLI's model flag after alias resolution
(3C.3). The z.ai GLM-in-Claude-Code env recipe (F7) remains a documented,
unverified option since it rides the claude CLI.

**3C.2 Resolution order** (per role, first hit wins — F11 precedence):
1. Repo config `.architect/config` — committed via a gitignore exception
   (`!.architect/config`), so a team shares it; everything else under
   `.architect/` stays ignored.
2. User config `~/.architect/config` (POSIX `$HOME` / Windows
   `%USERPROFILE%` — both resolvable from any harness's shell, C2
   research).
3. Defaults: brain = the running session (no resolution — it already IS
   the brain, model and effort as launched); brawn = same family one step
   down per the alias table (`claude → claude/sonnet`;
   `codex → gpt-5.5:high`). Separately, the review-gate backend defaults
   to the *other* CLI of the pair when on PATH (F10 applied at judging,
   not building); if absent, review falls back to a fresh same-CLI
   context with the bias caveat logged.

Format: flat `key = value` lines — trivially readable by any agent's file
tool, no parser dependency. The loop driver reads the same file for its
launch commands, so config binds both interactive and loop modes. The
user never has to hand-author it: when the human tells the architect to
change models ("use codex as the builder"), the skill writes the config
file — and the gitignore exception, on first repo-level write — itself.

**3C.3 Alias table — the single deliberate rot point.** dispatch.md hosts
one table mapping tier aliases to pinned slugs (`codex/best → -m gpt-5.5
-c model_reasoning_effort="xhigh"`; `claude/best → --model opus --effort
xhigh`; ...) **plus one tier-down row per CLI**:
- `claude → --model sonnet` (Sonnet 5; effort per the step-4 effort call).
- `codex → -m gpt-5.5 -c model_reasoning_effort="high"` — effort-down on
  the frontier model, NOT model-down: verified 2026-07-02 — ChatGPT-plan
  Codex quota is token-based so high burns ~2/3 of xhigh; gpt-5.4-mini is
  officially scoped to subagents/single-file work, not multi-hour builds;
  stet.sh effort curve puts high at 96% tests / 69% human-PR equivalence,
  and the residual review-pass gap vs xhigh is what the brain's review
  gate exists to catch. Amp's variable-effort-single-model practice
  corroborates (developers.openai.com/codex/models; stet.sh;
  ampcode.com/models/gpt-5.5).
**General tier-down rule the table implements:** same family, one step
down — for claude the step is the model (fable → sonnet, opus → sonnet,
sonnet → haiku) at effort high; for codex the step is effort (xhigh →
high) on the frontier model. Both CLIs are verified safe builders (F12
policy enforcement for claude, F13 kernel enforcement for codex); no
other builder runtimes are in scope (F13 recorded the exclusions:
gemini/pi cannot enforce no-commit unattended, agy unverified).
The step-4 effort call operates relative to the alias baseline: the
architect upgrades integration-/concurrency-heavy lanes to xhigh and may
downgrade routine tightly-specified lanes, recording which and why in the
spec. Dispatch always pins explicit model flags (dispatch.md's existing
silent-fallback warning stands) but the pin comes from this one table,
reviewed per model generation under the existing Maintenance rule. Users
who pin raw slugs in config own the rot (F9, Claude Code policy).

**3C.4 Degradation policy** (F9): configured brawn CLI absent at preflight
→ fall back to the tier-down default; write one line to the handoff naming
requested vs substituted. Cross-family review backend absent → review gate
runs on a fresh same-CLI context, with a logged caveat that same-family
bias applies (F10). Never hard-fail on model availability.

**3C.5 Brain detect + advise — never self-switch** (F6). Grounding step:
detect the harness (`CLAUDECODE`, `CODEX_HOME`), note the launch-time
model if discoverable. When a cross-family CLI is available but unused as
brawn → one-line advisory naming it and the config line that would switch
(upgrade-available tone, not misconfiguration — tier-down same-family is
the chosen default). When the brain is a known-weak tier for judgment →
warn and proceed. Running under any harness other than Claude Code or
Codex → the skill states the support scope, proceeds best-effort with
whichever of claude/codex is on PATH as brawn, and notes the caveat in
the handoff.

**3C.6 Builder-backend contract** (dispatch.md restructure, F8). A brawn
backend must provide: headless one-shot with stdin/file prompt; per-run
model + effort flags; unattended permission control; JSONL event stream +
final-message-to-file (liveness checks and stall detection depend on the
growing event file); worktree compatibility. Verified templates ship for
**codex** (canonical, `.git`-protected) and **claude**
(`claude -p --model <x> --effort <y> --output-format stream-json
--permission-mode dontAsk --allowedTools "Read" "Edit" "Write"
"Bash(<gate commands>:*)" "Bash(git status:*)" "Bash(git diff:*)"
--disallowedTools "Bash(git commit *)" "Bash(git push *)"` — F12: the
allowlist omits commit AND the deny rules outrank any future allowlist
mistake, so no-commit is enforced by permissions, not just instruction;
per-lane post-flight keeps the `git log <freeze-sha>..HEAD` +
branch-state check as the detection backstop). These are the only two
backends — other CLIs are out of scope (F13 records why). First use of
either backend in an environment requires the existing one-canary rule.

**3C.7 Audit trail** (F11, superpowers precedent). Every dispatch block
header states the resolved brawn (cli/model/effort); the handoff Session
log gains Brain and Brawn columns; the loop driver logs the brain per
iteration. Every run's models are reconstructable from the repo.

---

## 4. File-by-file changes

**4.1 NEW `skills/architect/loop.md`** (progressive disclosure, R12).
All Part B mechanics: sentinel protocol, WAIT fast path, driver usage +
rails, harness invocation table, chained-fallback commands verbatim
(exact `Start-Process` / `tmux new-session -d` / `setsid` / `claude --bg`
lines with their caveats, F3/F4), one-time setup checklist
(bypassPermissions acceptance).

**4.2 NEW `bin/architect-loop.sh` + `bin/architect-loop.ps1`** — reference
drivers (~80 lines), installed by install.sh/.ps1. Zero flags required —
bare `architect-loop` in a repo is the quick start. Optional flags only:
`--max-iters`, `--max-hours`, `--permissions`, `--brain`, `--brawn`
(the last two override the config chain, 3C.2; the brain string also
selects the harness, so there is no separate harness flag; WAIT-iteration
model choice is automatic per 3B.2, not a flag). Loop shape: preflight
(CLI on PATH, no `docs/STOP`; a missing `docs/HANDOFF.md` is a warning,
not a block — the first iteration bootstraps it, and the sentinel
fail-safe still stops the loop if that session writes nothing) → invoke
harness one-shot env-stripped, stdout→log → parse `LOOP:` sentinel
(missing → STOP) → breaker bookkeeping → CONTINUE / sleep-WAIT / STOP
with reason + log tail. The driver's terminal is the human's watch
surface (F3).

**4.3 `skills/architect/SKILL.md`** (kept thin — ~15 added lines total):
- Step 0: resolve brain/brawn per 3C.2; detect harness; the 3C.5 warn
  rule; if driver-launched (`ARCHITECT_LOOP=1` env), check the WAIT fast
  path.
- Step 4 Tool guidance: stall-plan §3.3 spec-writing rule (name known-bad
  patterns as forbidden with evidence; exact command forms, not examples).
- Step 5: stall rule points at the loop WAIT cycle (loop mode) or Part A's
  rescue ladder (manual).
- New final step: write the `LOOP:` sentinel (loop mode) or tell the human
  the exact next action (today's behavior).
- Hard rule 8 addition: in loop mode, stop = `LOOP: STOP (reason)`, never
  a silent exit.

**4.4 `skills/architect/dispatch.md`:**
- Part A lands here with one amendment: extended sandbox-hang list
  (out-of-workspace temp paths), SANDBOX EXECUTION POLICY paragraph in
  the builder block (in-workspace temp; sequential gates;
  **graduated timeouts** — the spec declares realistic ceilings for the
  repo's known-long commands (test suite, build) learned at grounding;
  600s is only the default for commands the spec did NOT declare;
  on timeout: record it, then one retry with a doubled ceiling IF the
  output showed forward progress, else report as a stall — never blind
  retry loops; the never-retry-same-path rule stays scoped to
  sandbox/filesystem errors, its original target), the 3-rung rescue
  ladder + rescue-block template (kill children system-wide by command
  signature → `codex exec [flags] resume <thread-id>` with the
  flags-before-subcommand gotcha → discard lane), the codex per-command
  timeout-cap investigation (if such a config cap exists, set it to the
  spec's largest declared ceiling, not a blanket 600s). Rationale for the
  amendment: a blanket cap converts slow-but-healthy commands (25-min
  suites, big builds) into false failures the builder would wrongly route
  around; the architect's WAIT-cycle liveness check (3B.2) is the
  catch-all for true stalls, bounding worst-case loss to one check-in
  interval regardless of any single command's ceiling.
- Part C: "Builder backends" section (3C.6 contract + verified templates +
  unverified list), the alias table (3C.3), the preference order +
  degradation policy (3C.4), audit-trail requirement (3C.7). The hardcoded
  `-m gpt-5.5` becomes the `codex/best` alias resolved from the table.

**4.5 `skills/architect/HANDOFF.template.md`:** `LOOP:` line in the TL;DR
(three forms + fail-safe note); Brain/Brawn columns in the Session log.

**4.6 `DESIGN.md`** — the evidence home for every feature (user
requirement):
- §7 rewrite: human-between-blocks stays the default; loop mode is the
  productized extension §7 already anticipated. Cite F1–F5.
- NEW section "Model roles": brain/brawn configurability; inherit-brain +
  tier-down-brawn defaults (opusplan precedent + human decision
  2026-07-02, with the quota tradeoff stated); cross-family diversity
  spent at the review gate (F10); degradation and alias policy. Cite
  F6–F11 (incl. arXiv:2410.21819, goose#4036, aider issues, opusplan
  docs, z.ai docs).
- Stall prevention: fold Part A's root-cause chain + citations into the
  failure-mode table ("Stalled unattended runs" row → driver WAIT cycle);
  add "Runaway loop" row (fail-safe sentinel, caps, breaker, kill file).
- Corrections: stale Agent-SDK-credits claim (F4d); note `.git` protection
  is codex-verified-only (F8).
- Standing rule appended to the Maintenance section of SKILL.md and
  mirrored in DESIGN.md: **no feature ships without its evidence recorded
  in DESIGN.md** — a PR adding behavior without a DESIGN.md entry is
  incomplete by definition.

**4.7 `README.md`, installers, `tests/validate_skills.py`:** README gains
"Run it as a loop" (driver quick-start, stop mechanisms, quota note) and
"Choosing your models" (the two-key config, the two-harness defaults
table, the one-line override example `brawn = codex/best`, GLM recipe
marked unverified). Installers copy `bin/`. Tests: loop.md
links/fences; drivers exist + `bash -n`/PSScriptAnalyzer-parse clean;
sentinel regex round-trips all three forms; alias table entries resolve to
non-empty flag strings; config-example parses.

---

## 5. Verification gates for this work

1. `python tests/validate_skills.py` passes with all new files.
2. **Loop canary (this Windows machine):** driver launched detached from
   inside a Claude Code session survives session end; iteration 1 starts a
   fresh `claude -p` that loads /architect (transcript shows grounding,
   not resumed context); env-strip prevents the nested hang (10 launches,
   0 hangs — the #26190 repro bar).
3. **Three-iteration dry run** (toy repo, trivial slice): iteration 1
   (full brain) dispatches a builder, writes `LOOP: WAIT`; driver sleeps;
   iteration 2 (tier-down brain, automatic) finds lanes complete, writes
   `LOOP: CONTINUE` **without judging**; iteration 3 (full brain) judges
   and writes `LOOP: STOP (goal met)`. Confirm three distinct session
   IDs, the WAIT session's model differs from the judgment session's
   (audit trail proves it), sentinel parsed each time, logs present,
   `docs/STOP` mid-run kills the loop, and a healthy in-flight lane does
   NOT trip the circuit breaker across 3 WAIT ticks (lane growth counts
   as progress).
4. **Fail-safe test:** delete the `LOOP:` line → driver stops.
5. **Config resolution test:** user config sets `brawn = claude/best`;
   repo config sets `brawn = codex/best`; dispatch uses codex and the
   handoff audit line says so. Remove repo config → claude template used,
   compensating `.git` post-flight check runs.
6. **Default + degradation tests:** (a) no config, Claude Code on Fable,
   codex on PATH → brawn resolves to `claude/sonnet`, the
   cross-family-available advisory prints, and a high-stakes review gate
   routes to codex; (b) config names a CLI not on PATH → dispatch falls
   back to tier-down and writes the requested-vs-substituted warning;
   (c) only one CLI present → review-gate same-family caveat appears in
   the handoff.
7. **Claude-as-brawn canary:** one real lane dispatched via `claude -p` in
   a worktree — lane report written, event stream grows (liveness works),
   a deliberate `git commit` attempt in the lane is DENIED (dontAsk deny
   visible in the stream-json output), post-flight commit check passes.
8. **Allowlist bootstrap test:** first architect session in a fresh repo
   writes `.claude/settings.json` permissions.allow with the gate
   commands + git ops and logs it in the handoff Decisions table; a
   second `-p` session then runs a gate command without aborting.
9. Part A's own verification items (its §4) carried over, EXCEPT its
   "no gate command may exceed 600s" criterion, superseded by the
   graduated policy: instead verify the next real dispatch declares
   per-command ceilings for the repo's gate commands and 600s applies
   only to undeclared commands. Worst-case stall detection ≤ one WAIT
   interval stands.

## 6. Risks and open questions

- **`claude --bg` env-strip interaction is partly inferred** — canary
  before loop.md asserts it (research flag).
- **Quota burn:** N iterations × grounding cost; mitigated by the WAIT
  fast path running automatically on the tier-down brain, not solved.
  Documented in README.
- **Billing pause reversal** (F4d): loop.md carries a dated recheck note.
- **Non-codex brawn `.git` protection unverified** (F8): the compensating
  post-flight control is detection, not prevention — weaker guarantee,
  stated plainly in dispatch.md.
- **GLM-5.2-in-Claude-Code unverified in primary sources** (F7): shipped
  as a documented recipe marked unverified + gray-zone note
  (Anthropic-unblessed, z.ai-supported); user canaries with their own key.
- **Codex-as-architect chaining:** under Codex's sandbox the chained
  fallback likely cannot detach (F3 Job Object) — the driver is the only
  supported loop there; loop.md says so.
- **One-time interactive setups** can't be automated by design
  (bypassPermissions acceptance; z.ai env vars) — documented install
  steps.
- **Alias-table rot is deliberate and owned:** one table, one review per
  model generation (existing Maintenance rule). Watch item: a possible
  silent gpt-5.6 rollout was search-surfaced but unconfirmed — recheck the
  codex rows at implementation.
- **Tier-down default concentrates quota:** builder hours now land on the
  same subscription as judgment (vs the old cross-vendor split that put
  typing hours on the flat-rate ChatGPT plan). Chosen deliberately for
  zero-dependency UX (human decision 2026-07-02); the cross-family
  advisory + one config line is the escape hatch. DESIGN.md documents
  both the F10 bias tradeoff and this economics tradeoff.
- **Codex brain runs unsandboxed** (`danger-full-access` is the only mode
  with `.git` write): the judgment role gets full host access under
  codex — acceptable because the brain runs trusted skill text, but
  stated plainly in loop.md; users who want a sandboxed brain should run
  the brain under Claude Code (dontAsk + allowlist) instead.
- **Out-of-scope harnesses** (pi/opencode/gemini/antigravity): cut per
  the 2026-07-02 scope decision, with F13 as recorded rationale; revisit
  is a DESIGN.md note (e.g. if gemini's policy-engine bugs #17728/#20469
  close or agy's docs become verifiable). The codex `--ask-for-approval`
  doc-vs-live conflict is resolved by omitting the flag (both sources
  agree exec never prompts); re-canary at implementation.
- **Autonomy scope:** loop mode removes the human from between blocks —
  arbitration rulings that previously waited default to the architect
  unless the spec marks them human-only; `LOOP: STOP` is the guard and the
  DESIGN.md §7 rewrite states the trade explicitly.
