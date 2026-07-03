# rename-product-docs-01

## PHASE 0

### Plan

| Step | Files |
|---|---|
| Verify input HEAD and frozen check file | git, docs/gates/rename-product-docs.md |
| Read rename spec and frozen checks | docs/spec/rename-domain-language.md, docs/gates/rename-product-docs.md |
| Inspect allowed content files for old vocabulary and exceptions | README.md, DESIGN.md, CONTEXT.md, assets/architect-flow.html, assets/research-flow.html |
| Apply rename table to allowed content files | README.md, DESIGN.md, CONTEXT.md, assets/architect-flow.html, assets/research-flow.html |
| Run frozen checks sequentially | docs/gates/rename-product-docs.md |
| Record verbatim command output | docs/lanes/rename-product-docs-01.md |

### Disagreements / Scope Notes

| Item | Evidence | Result |
|---|---|---|
| Report file is outside the five content files listed under MAY TOUCH, but the issue explicitly requires `docs/lanes/rename-product-docs-01.md` and spec A2 says this run's job reports follow `docs/lanes/`. | `docs/spec/rename-domain-language.md`; issue report instruction | Proceeding with required report file only in addition to the five listed content files. |
| No blocking disagreement found before edits. | `docs/spec/rename-domain-language.md`; `docs/gates/rename-product-docs.md`; initial sweep of README.md, DESIGN.md, CONTEXT.md, assets/architect-flow.html, assets/research-flow.html | Proceeding. |

### First-Action Verification

Command:

```text
git log -1 --oneline
```

Output:

```text
3c88dea merge job rename-research-skill-01 (judge PASS, #32)
```

Command:

```text
Test-Path -LiteralPath 'docs/gates/rename-product-docs.md'; if (Test-Path -LiteralPath 'docs/gates/rename-product-docs.md') { Get-Item -LiteralPath 'docs/gates/rename-product-docs.md' | Select-Object -ExpandProperty FullName }
```

Output:

```text
True
C:\Users\danhm\architect-loop\.architect\wt\rename-product-docs-01\docs\gates\rename-product-docs.md
```

### Initial Sweep

Command:

```text
rg -n "gate|gates|gated|lane|lanes|brain|brawn|cold|epic|grill|grilled|grilling|dag|DAG|frontier|stop rail|spec gate|docs/STOP|skills/architect-research/lanes\.md|Brain|Default brawn|Materiality-gated|Materiality-tested|kill file|kill switch" README.md DESIGN.md CONTEXT.md assets/architect-flow.html assets/research-flow.html
```

Output:

```text
assets/research-flow.html:13:  .lanes { display:flex; flex-direction:column; gap:6px; margin-top:10px; }
assets/research-flow.html:14:  .lane { border:1.5px solid #1f6f58; border-radius:8px; padding:3px 8px; font-size:14px; color:#7ee2c3; background:#0a221b; }
assets/research-flow.html:33:      <div class="does">designs the lanes<br>sets tool-call budgets</div>
assets/research-flow.html:39:      <div class="lanes">
assets/research-flow.html:40:        <div class="lane">lane 1</div>
assets/research-flow.html:41:        <div class="lane">lane N</div>
assets/research-flow.html:60:  <div class="legend"><span class="snow">❄</span> = a fresh agent with no memory of the conversation · researchers use the same brain/brawn config as the build loop</div>
assets/architect-flow.html:9:  .cold  { background:#0d1826; border:3px solid #58a6ff; }
assets/architect-flow.html:12:  .fable .who { color:#d97757; } .cold .who { color:#79b8ff; } .build .who { color:#3fd0a4; } .human .who { color:#c69df9; }
assets/architect-flow.html:16:  .lanes { display:flex; flex-direction:column; gap:5px; margin-top:9px; }
assets/architect-flow.html:17:  .lane { border:1.5px solid #1f6f58; border-radius:8px; padding:2px 7px; font-size:13px; color:#7ee2c3; background:#0a221b; }
assets/architect-flow.html:42:      <div class="does">cuts a GitHub issue DAG<br>freezes gates in git<br>one cold grill attacks it all</div>
assets/architect-flow.html:48:      <div class="does">code the unblocked issues<br>can't commit, can't touch gates</div>
assets/architect-flow.html:49:      <div class="lanes">
assets/architect-flow.html:50:        <div class="lane">worktree lane 1 … 5</div>
assets/architect-flow.html:55:    <div class="box cold">
assets/architect-flow.html:58:      <div class="does">runs the frozen gates<br>reads diff vs intent<br>a FAIL can't be overruled</div>
assets/architect-flow.html:64:      <div class="does">merges on PASS<br>answers blockers, respawns<br>next frontier → one PR</div>
assets/architect-flow.html:67:  <div class="loop">⟲ steps 4–6 repeat, unattended, until every issue in the DAG is closed</div>
assets/architect-flow.html:70:    <div class="does">epic + issue DAG · spec + frozen gates + rulings in git · lane reports · verdicts on issues — not in the tracker = didn't happen</div>
CONTEXT.md:7:- **Orchestrator** (colloquially **the brain**) — the single interactive
CONTEXT.md:10:  writes implementation code, never reads large diffs, never judges gates.
CONTEXT.md:11:- **Brain** — the model tier the orchestrator runs on. Also the judge's
CONTEXT.md:12:  tier: "the brain" names a capability level, not one process.
CONTEXT.md:13:- **Builder** (colloquially **brawn**) — a cold-context worker agent that
CONTEXT.md:15:  brawn tier is typically cheaper than the brain tier and never changes
CONTEXT.md:16:  because a lane failed.
CONTEXT.md:17:- **Judge** — a cold-context, read-only agent at brain tier that runs an
CONTEXT.md:18:  issue's frozen gates and returns verdicts with raw evidence. "The brain
CONTEXT.md:22:  in-flight lanes (~10 min) and exits with evidence on anomaly. Never
CONTEXT.md:24:- **Grill** — a cold adversarial reviewer of the decomposition before the
CONTEXT.md:25:  freeze: attacks gate commands, issue bodies, and repo reality.
CONTEXT.md:26:- **Scout** — a lane-shaped investigator: reads, researches, reports; may
CONTEXT.md:32:  builder lane. Body carries what-to-build, acceptance criteria, boundaries
CONTEXT.md:36:- **DAG / frontier** — the dependency graph of issues; the schedulable set
CONTEXT.md:37:  is always the unblocked frontier, dispatched up to five lanes at once.
CONTEXT.md:38:- **Wave** — one frontier dispatch: its lanes plus one monitor.
CONTEXT.md:39:- **Factory run** — everything between spec-gate approval and the closing
CONTEXT.md:45:  assignments, progress and verdicts are comments, the epic carries the
CONTEXT.md:47:- **Spec gate** — the one human step: review one spec document, edit or
CONTEXT.md:48:  veto its recorded assumptions, approve. Approval authorizes the DAG.
CONTEXT.md:50:  (`docs/gates/<issue-slug>.md`). Read-only for everyone once frozen.
CONTEXT.md:51:- **Freeze commit** — the commit that locks a run's gates; it is pushed
CONTEXT.md:53:- **Rulings file** (`docs/lanes/<issue-slug>-rulings.md`) — orchestrator-
CONTEXT.md:56:- **Verdict comment** — the judgment record posted on the issue: per-gate
CONTEXT.md:57:  PASS/FAIL/INVALID, gates integrity, diff-vs-intent, and the slice call.
CONTEXT.md:58:- **Canary** — the preflight spawn that proves a brawn backend actually has
CONTEXT.md:61:  `.architect/config` that route task classes to brawn tiers; absent file =
CONTEXT.md:63:- **Post-flight** — the orchestrator's mechanical checks on a completed lane
CONTEXT.md:64:  (boundaries, gates-file integrity, raw-only report, status-line form)
CONTEXT.md:69:- **docs/STOP** — kill file; its presence halts the factory before the next
README.md:5:The model you're talking to, Claude or Codex, acts as the **brain**: it
README.md:7:blockers, and judges results. Disposable **brawn** agents write the code in
README.md:9:gates that were locked in before the code existed, and the brain is not
README.md:13:an epic with sub-issues and native blocked-by links; rulings, blocker
README.md:16:specs and frozen gates; lane reports keep raw command output. A later
README.md:23:factory that only interrupts you for a stop rail or the closing digest.
README.md:31:1. **Intake.** The brain reads the repo and asks at most about five questions
README.md:35:2. **Spec gate.** You review one document under `docs/spec/`. You can edit
README.md:38:3. **Factory loop.** The brain turns the approved spec into a GitHub issue
README.md:39:   DAG: one epic, sub-issues, and native blocked-by links. It freezes each
README.md:40:   issue's gates under `docs/gates/`, dispatches the unblocked frontier, and
README.md:41:   keeps going until the DAG is closed or a stop rail fires.
README.md:43:The factory can run up to five brawn lanes at once, plus one cheap
README.md:44:detection-only monitor. The monitor checks for stalled lanes every roughly
README.md:46:It never kills or nudges anything; it exits with evidence, and the brain
README.md:49:On a passing issue, the brain records the judge verdict on the issue and
README.md:50:merges. On a blocker, the brawn lane stops, the brain answers on the issue,
README.md:51:and a fresh lane is respawned with the answer in its starting context. On a
README.md:52:gate failure, the brain diagnoses the input and respawns at the same tier;
README.md:65:| Materiality-gated intake | The brain asks only the few questions that can change the build or validation plan |
README.md:66:| One spec gate | You review one spec document, then the factory is authorized to run |
README.md:67:| GitHub issue DAG | Epic, sub-issues, and native blocked-by links are the durable coordination state |
README.md:68:| Unblocked frontier dispatch | The brain runs only issues whose blockers are closed, up to five lanes |
README.md:69:| Frozen gates | Acceptance commands live in `docs/gates/` and cannot be changed after dispatch |
README.md:71:| Detection-only monitor | Stalls wake the brain with evidence; the monitor never kills or decides |
README.md:72:| Builder boundaries | Each lane gets a may-touch and must-not-touch set, then reports raw evidence |
README.md:73:| Builders can't commit | Nothing reaches a branch until the brain verifies and the judge rules |
README.md:75:| Docs debt | One final docs lane updates product docs and records reusable lessons |
README.md:76:| `docs/STOP` | Drop this file in the repo and the factory halts before its next dispatch |
README.md:89:working brawn backend instead of switching mid-wave.
README.md:123:monitor agents the shell tools their gates require.
README.md:127:Zero-config defaults: the brain is whatever session you launched; brawn is
README.md:131:| Harness you launched | Codex CLI on PATH? | Brain | Default brawn |
README.md:143:brain = claude/best
README.md:146:brawn = codex/best:xhigh
README.md:153:not automatically move a failed lane to a stronger model; the brain diagnoses
README.md:169:topic; Fable designs 3-6 research lanes along the topic's own fault lines;
README.md:170:parallel researchers, resolved from the same brain/brawn config as the
README.md:182:| [skills/architect/SKILL.md](skills/architect/SKILL.md) | The brain role: intake, spec gate, factory loop, and stop rails |
README.md:187:| [skills/architect-research/lanes.md](skills/architect-research/lanes.md) | Source-class tactics library for research lanes |
README.md:196:**What does a run cost?** Brain judgment is minutes of a frontier model;
README.md:197:building happens on the configured brawn tier. A long multi-lane run is a
README.md:199:fans out when the issue DAG is ready for it.
README.md:202:have no commit access, their file boundaries are checked after every lane,
README.md:203:and broken worktrees are discarded and respawned from the frozen gate.
README.md:216:much stronger with a few operational rules: frozen gates, cold review,
DESIGN.md:3:**The design rationale for an autonomous software factory.** The brain model
DESIGN.md:5:decomposes it into a GitHub issue DAG, dispatches parallel cold builder lanes
DESIGN.md:6:into worktrees, answers blockers, sends cold judges against frozen gates, and
DESIGN.md:7:merges — with exactly one human step, the spec gate. This document is the
DESIGN.md:8:"why", with citations; the skill files in `skills/architect/` are the "how";
DESIGN.md:66:| **Orchestrator (brain)** | the session the human opened | intake, spec, decomposition, gate freeze, dispatch, blocker answers, merge decisions, digest |
DESIGN.md:67:| **Builder (brawn)** | cold worker agent, one per issue, own worktree | implementation and raw-evidence reporting only |
DESIGN.md:68:| **Judge** | cold brain-tier agent, read-only | frozen-gate verdicts and diff-vs-intent |
DESIGN.md:70:| **Grill** | cold adversarial reviewer, pre-freeze | falsifying the decomposition before it's authorized |
DESIGN.md:71:| **Human** | you | the spec gate, stop rails, taste |
DESIGN.md:73:Why the brain does the design work and the brawn only builds:
DESIGN.md:81:Why the judge is a *separate cold context* at brain tier rather than the
DESIGN.md:106:frozen gates, rulings files, lane reports.
DESIGN.md:118:  up to the lane cap" — no custom state files or body-text conventions.
DESIGN.md:120:  lane's lifecycle wanted a row in it, which fought the disjoint-file-set
DESIGN.md:121:  rule that makes parallel lanes safe. Issues give each unit of work its own
DESIGN.md:124:  blocker answers, verdicts, and the epic digest are readable from GitHub
DESIGN.md:149:### Intake and the spec gate
DESIGN.md:151:- **At most ~5 materiality-gated questions, in one batch (D3).** GitHub Spec
DESIGN.md:155:  established middle path between maximal grilling and zero questions
DESIGN.md:158:- **The spec gate is the one human step (D4).** The human reviews one
DESIGN.md:160:  Approval authorizes the entire issue DAG — after it, the human hears from
DESIGN.md:161:  the factory only through the epic digest or a stop rail. Concentrating
DESIGN.md:167:- **Backend canary before decomposition (v5.1 D1).** Every candidate brawn
DESIGN.md:169:  DEGRADED backend is substituted *before* the DAG records tiers, with the
DESIGN.md:170:  evidence on the epic. Motivated by 6/6 Claude subagent spawns losing shell
DESIGN.md:176:- **Vertical slices as issues, dispatched by unblocked frontier (D5).** Each
DESIGN.md:182:  The parallel set is always the DAG's unblocked frontier, capped at five
DESIGN.md:183:  lanes plus one monitor.
DESIGN.md:188:  a small lane cap
DESIGN.md:192:  conflict is therefore treated as a *decomposition* failure: kill the lane
DESIGN.md:200:  applied between lanes, and it avoided merge conflicts in the dogfood runs
DESIGN.md:203:  separate issues with a blocking edge (structural gates prove existing
DESIGN.md:208:  in the spec so lanes don't invent them mid-flight (TDD sourced from
DESIGN.md:213:  a spec that will exceed the target splits into more lanes or issues.
DESIGN.md:215:### Frozen gates and the grill
DESIGN.md:223:  `docs/gates/<issue-slug>.md`, freeze at one commit, and **any builder edit
DESIGN.md:224:  under `docs/gates/` is an automatic FAIL regardless of results**. Visible
DESIGN.md:235:- **One cold grill pass attacks the whole decomposition (P2, widened by
DESIGN.md:237:  draft gate commands against the current tree, attacks acceptance criteria
DESIGN.md:239:  files the DAG deletes or renames, and checks new artifact paths against
DESIGN.md:243:  blocking gate defects (§7).
DESIGN.md:247:- **Fresh cold builder per issue; respawn over resume (D7).** The Ralph
DESIGN.md:252:  When a lane blocks or wedges, the orchestrator answers durably on the
DESIGN.md:253:  issue and spawns a *new* cold lane with the answer in its spawn context —
DESIGN.md:262:- **PHASE 0: disagreement is mandatory.** Before building, every lane states
DESIGN.md:264:  it checked before finding none. Silent compliance is a lane defect.
DESIGN.md:275:  defaults can fake a passing gate while the primary path is broken. Sources:
DESIGN.md:280:  limits are recorded and routed to a stop rail, never worked around
DESIGN.md:283:  guidance, boundaries, rulings, and the frozen-gate pointer travel in one
DESIGN.md:290:- **Nobody grades their own work.** The builder reports evidence; a cold
DESIGN.md:291:  brain-tier judge runs the frozen gates itself (builder claims are
DESIGN.md:292:  hearsay) and returns per-gate **PASS / FAIL / INVALID** — INVALID meaning
DESIGN.md:293:  "not measured the way the gate specifies", so unmeasured never equals
DESIGN.md:300:  upon. Judgment context is pointer-only — frozen gate file, spec, lane
DESIGN.md:313:  `docs/lanes/<issue-slug>-rulings.md`, orchestrator-owned, committed before
DESIGN.md:320:- **BLOCKED is a completion event.** The lane posts the exact blocker plus
DESIGN.md:338:- **The monitor detects; the brain rules (D6).** One cheapest-tier,
DESIGN.md:342:  the kill decision at brain tier keeps a cheap model from destroying an
DESIGN.md:345:- **Stop rails (D11).** `docs/STOP` before any wave; irreversible actions;
DESIGN.md:347:  (a spec-gate decision surfacing late); scope growth beyond the approved
DESIGN.md:353:- **Brain, brawn, judge, and monitor are configurable roles, not brand
DESIGN.md:360:- **Default brawn is codex-first.** `codex/best` (gpt-5.5, xhigh) whenever
DESIGN.md:370:- **Optional cross-vendor gateways are documented as asymmetric and
DESIGN.md:371:  unverified.** Claude Code accepts Anthropic-compatible gateways via
DESIGN.md:379:  closing PR.** The PR body closes the epic and lists every shipped issue;
DESIGN.md:381:- **Docs debt batches into one dedicated lane at the PR boundary (P7).**
DESIGN.md:383:  repo and evidence rows need post-judgment information, so build lanes and
DESIGN.md:385:  docs lane consumes them before the PR.
DESIGN.md:417:- **Scout-first, topic-designed lanes — no fixed taxonomy.** All five
DESIGN.md:423:  lines; the orchestrator designs 3–6 lanes from that map, drawing
DESIGN.md:424:  source-class tactics from `lanes.md`. Perspective discovery was STORM's
DESIGN.md:428:- **Hard budgets per lane.** Researcher counts scale 1/2–4/4–6 by tier;
DESIGN.md:432:  heuristics — without them, leads over- or under-delegate.
DESIGN.md:435:  lanes at 2,000–3,600 tokens with citations; per-URL tag citations removed
DESIGN.md:459:| Reward hacking / gate tampering | Gates frozen in git pre-dispatch; `git diff` integrity check at judgment; tampering = automatic FAIL |
DESIGN.md:460:| Builder grades own work | Raw-evidence-only reports; cold judge runs gates itself; cross-family review for high-stakes |
DESIGN.md:461:| Goalpost moving | Verbatim frozen gate text; gates read-only after freeze; missing gate = spec defect for the *next* issue |
DESIGN.md:462:| Scope creep | Explicit boundaries and out-of-scope per issue; silent additions = lane failure; scope growth beyond spec = stop rail |
DESIGN.md:463:| Context rot | Orchestrator holds judgment only, never reads large diffs; fresh cold lane per issue; tracker + git carry state |
DESIGN.md:464:| Merge conflicts between lanes | Disjoint mutable-state sets, ≤5 lanes, worktrees; conflict = decomposition failure, re-spec |
DESIGN.md:465:| Placeholder implementations | End-to-end executable gate commands; "search before implementing; full implementations only" in the builder block |
DESIGN.md:468:| Gate-passing but unmergeable work | Judge reads diff vs intent, not gate output alone (METR) |
DESIGN.md:469:| Builder gaming visible gates | Frozen read-only gates; no iterate-against-judge loop (ImpossibleBench 33%→38%) |
DESIGN.md:470:| Stalled lanes | Detection-only monitor: growth + process + repeated-action checks; brain rules on evidence; no kill ceilings |
DESIGN.md:471:| Runaway factory | `docs/STOP`; two-consecutive-KILL rail; assumption-collision rail; epic digest as the human channel |
DESIGN.md:474:| Researcher context exhaustion | ≤5 subjects per lane; compact returns; bisect dead lanes |
DESIGN.md:481:- **Not same-session self-continuation.** Every unit of work gets a cold
DESIGN.md:483:  lane output. Ralph-style same-session loops are the documented
DESIGN.md:494:  internally; this design adds what it lacks — frozen external gates, cold
DESIGN.md:495:  cross-model judgment, issue-DAG coordination, and repo-resident evidence.
DESIGN.md:496:- **Not human-free.** Autonomy is bounded by the spec gate at the front and
DESIGN.md:497:  stop rails throughout; kill/continue authority inside the run belongs to
DESIGN.md:520:  after spawn; never run two Claude-backend lanes concurrently without
DESIGN.md:527:  (workspace-write, tree audited untouched) for shell-dependent gates, plus
DESIGN.md:528:  a cold headless `claude -p` session for gates the Codex sandbox cannot
DESIGN.md:535:- **Sandbox substitutions, recorded per gate:** `uv` AppData cache denial →
DESIGN.md:540:  paths and sequential gate execution.
DESIGN.md:541:- **Grill catch record:** 5 draft-gate defects (first use), 8 (second), 2
DESIGN.md:543:- **Dogfood runs.** v5 was built *by* the factory as a real issue DAG (epic
DESIGN.md:544:  #12, issues #13–#18): 1 judge FAIL, 3 respawns, all lanes cold-judged.
DESIGN.md:545:  The v5.1 hardening run (epic #20, issues #21–#25, on `factory/v5.1`)
DESIGN.md:547:  canary preflight, freeze-push-dispatch, extended grill, rulings files.
```

## Mirror

```text
MIRROR: ORCHESTRATOR
```

## Touched Set

Command:

```text
git status --short
```

Output:

```text
 M CONTEXT.md
 M DESIGN.md
 M README.md
 M assets/architect-flow.html
 M assets/research-flow.html
?? docs/lanes/rename-product-docs-01.md
```

## Frozen Checks

### PD1.1

Executor: PowerShell

Command:

```text
git grep -inwE "gate|gates|gated|lane|lanes|brain|brawn|cold|epic|grill|grilled|grilling|dag" -- README.md assets/architect-flow.html assets/research-flow.html
```

Output:

```text
```

### PD1.2 Listed Command

Executor: PowerShell

Command:

```text
git grep -inE "frontier" -- README.md assets/architect-flow.html assets/research-flow.html | grep -ivE "frontier (model|codex|row|tier)|frontier-tier"
```

Output:

```text
      0 [main] grep (34724) C:\Program Files\Git\usr\bin\grep.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

### PD1.2 Same-Pattern Substitution

Executor: PowerShell

Command:

```text
$out = git grep -inE "frontier" -- README.md assets/architect-flow.html assets/research-flow.html; $out | Select-String -Pattern "frontier (model|codex|row|tier)|frontier-tier" -NotMatch
```

Output:

```text
```

### PD2.1

Executor: PowerShell

Command:

```text
git grep -inwE "gates?|gated|lanes?|brain|brawn|cold|epic|dag|grilling|grilled" -- DESIGN.md
```

Output:

```text
```

### PD2.2

Executor: PowerShell

Command:

```text
git grep -icw "grill" -- DESIGN.md
```

Output:

```text
DESIGN.md:1
```

### PD2.3

Executor: PowerShell same-pattern substitution

Command:

```text
$out = git grep -iw "grill" -- DESIGN.md; ($out | Select-String -Pattern "in earlier runs" | Measure-Object).Count
```

Output:

```text
1
```

### PD2.4

Executor: PowerShell same-pattern substitution

Command:

```text
$out = git grep -inE "frontier" -- DESIGN.md; $out | Select-String -Pattern "frontier (model|codex|row|tier)|frontier-tier" -NotMatch
```

Output:

```text
```

### PD2.5

Executor: PowerShell

Command:

```text
git grep -inE "stop rail|spec gate" -- DESIGN.md README.md
```

Output:

```text
```

### PD3.1

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $before = foreach ($line in $lines) { if ($line -eq '## Retired terms (historical; appear in pre-v5 docs and git history)') { break }; $line }; $before | Select-String -Pattern "\b(gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag|frontier)\b" -CaseSensitive:$false
```

Output:

```text
```

### PD3.2 gate

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bgate\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 dag

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bdag\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 cold

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bcold\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 epic

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bepic\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 brain

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bbrain\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 brawn

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bbrawn\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 lane

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\blane\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 grill

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bgrill\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 frontier

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern '\bfrontier\b' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD3.2 stop rail

Executor: PowerShell same-pattern substitution

Command:

```text
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $start = [Array]::IndexOf($lines, '## Retired terms (historical; appear in pre-v5 docs and git history)'); (($lines[$start..($lines.Length-1)] | Select-String -Pattern 'stop rail' -CaseSensitive:$false) | Measure-Object).Count
```

Output:

```text
1
```

### PD4.1

Executor: PowerShell

Command:

```text
git grep -liE "tracking issue" -- README.md DESIGN.md CONTEXT.md
```

Output:

```text
CONTEXT.md
DESIGN.md
README.md
```

### PD4.2

Executor: PowerShell

Command:

```text
git grep -cE "^orchestrator = " -- README.md
```

Output:

```text
README.md:1
```

### PD4.3

Executor: PowerShell

Command:

```text
git grep -cE "^builders = " -- README.md
```

Output:

```text
README.md:1
```

### PD4.4

Executor: PowerShell same-pattern substitution

Command:

```text
((Get-Content -LiteralPath 'assets/architect-flow.html') | Select-String -Pattern 'ORCHESTRATOR' -CaseSensitive:$false | Measure-Object).Count
```

Output:

```text
3
```

### PD4.5

Executor: PowerShell same-pattern substitution

Command:

```text
((Get-Content -LiteralPath 'assets/architect-flow.html') | Select-String -Pattern 'BUILDERS' -CaseSensitive:$false | Measure-Object).Count
```

Output:

```text
1
```

### PD4.6

Executor: PowerShell

Command:

```text
git grep -liE "frozen checks|acceptance checks" -- README.md DESIGN.md
```

Output:

```text
DESIGN.md
README.md
```

### PD4.7

Executor: PowerShell

Command:

```text
git grep -li "ready issues" -- README.md
```

Output:

```text
README.md
```

### PD4.8

Executor: PowerShell

Command:

```text
git grep -li "kill switch" -- README.md CONTEXT.md
```

Output:

```text
CONTEXT.md
README.md
```

### PD5

Executor: PowerShell

Command:

```text
Test-Path -LiteralPath 'skills/architect-research/tactics.md'
```

Output:

```text
True
```


STATUS: COMPLETE

## Respawn session

### Required artifact fix

Hit found and fixed:

```text
C:\Users\danhm\architect-loop\.architect\wt\rename-product-docs-01\assets\architect-flow.html:42:      <div class="does">cuts a the plan<br>freezes checks in git<br>one fresh stress-test attacks it all</div>
```

Fix applied:

```text
assets/architect-flow.html:42 changed "cuts a the plan" to "cuts the plan"
```

No legitimate pre-existing doubled-article hits were found.

### Doubled-article sweep

Command:

```text
Select-String -Path README.md,DESIGN.md,CONTEXT.md,assets\architect-flow.html,assets\research-flow.html -Pattern '\b(a|an|the)\s+the\s+|\ba\s+a\s+' -CaseSensitive:$false | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line)" }
```

Output:

```text
```

### PD1.1

Executor: PowerShell

Command:

```text
git grep -inwE "gate|gates|gated|lane|lanes|brain|brawn|cold|epic|grill|grilled|grilling|dag" -- README.md assets/architect-flow.html assets/research-flow.html
```

Output:

```text
```

### PD1.2 Listed Command

Executor: PowerShell

Command:

```text
git grep -inE "frontier" -- README.md assets/architect-flow.html assets/research-flow.html | grep -ivE "frontier (model|codex|row|tier)|frontier-tier"
```

Output:

```text
      0 [main] grep (37548) C:\Program Files\Git\usr\bin\grep.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

### PD1.2 Same-Pattern Substitution

Executor: PowerShell

Command:

```text
$out = git grep -inE "frontier" -- README.md assets/architect-flow.html assets/research-flow.html; $out | Select-String -Pattern "frontier (model|codex|row|tier)|frontier-tier" -NotMatch
```

Output:

```text
```

STATUS: COMPLETE
