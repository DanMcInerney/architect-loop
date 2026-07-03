# Builder dispatch reference

Dispatch turns a frozen slice into cold builder or judge work. The
orchestrator chooses the lane shape, model tier, worktree, and report path;
the subagent receives a self-contained task and returns raw evidence.

Verified local Codex facts from the v3 evidence remain useful for the Codex
backend path: the model slug is `gpt-5.5`; `--search` and
`-a/--ask-for-approval` are top-level `codex --help` flags, not `codex exec`
flags; `codex exec` is non-interactive; Goal Mode subcommands are bare
`/goal`, `/goal pause|resume|clear`.

## Model alias table

| Alias | Flags | Notes |
|---|---|---|
| `codex/best` | `-m gpt-5.5 -c model_reasoning_effort="xhigh"` | Frontier Codex row. Watch for a possible gpt-5.6 rollout before changing this pin. |
| `claude/best` | `--model opus --effort xhigh` | Best Claude Code judgment/build row. |
| `codex/tier-down` | `-m gpt-5.5 -c model_reasoning_effort="high"` | Effort-down on the frontier model; high is the quota-saving tier-down, not a model downgrade. Watch the codex rows per model generation. |
| `claude/tier-down` | `--model sonnet --effort high` | Model-down at high effort. |

General tier-down rule: same family, one step down. For Claude, the step is the
model at high effort (Fable/Opus -> Sonnet; Sonnet -> Haiku only when the
orchestrator explicitly chooses that risk). For Codex, the step is effort
(xhigh -> high) on the frontier model. Dispatch blocks print explicit pinned
flags in every command; this table is the source of those pins.

## Model resolution and dispatch rules

Role strings are `<cli>/<model-spec>[:<effort>]`, with `<cli>` in `{claude,
codex}`. Resolution order per role is repo `.architect/config`, then user
`~/.architect/config`, then defaults: brain = the running session; brawn =
tier-down per the alias table. Flat `key = value` lines are the supported
format for role keys. Unknown keys warn and never fail.

Optional dispatch-rules lines route task classes to a brawn tier:

```ini
# .architect/config or ~/.architect/config
brain = claude/best
brawn = codex/best
when trivial mechanical edit -> claude/haiku:low # cheap exact patch
when broad ambiguous refactor -> codex/best:xhigh # deeper search and edit budget
```

Format: `when <task-class description> -> <cli>/<model-spec>[:<effort>] # why`.
The trailing reason is optional but preferred. Absent file = tier-down default.
Absent dispatch rules = tier-down default. A matching rule is still a judgment
aid; the orchestrator records which rule was used and may override it with a
reason recorded on the issue.

Configured brawn CLI absent at preflight -> fall back to the tier-down default
and write one epic-issue comment naming requested vs substituted. Cross-family
review backend absent -> run review in a fresh same-CLI context and log the
same-family bias caveat. Never hard-fail on model availability alone. Tier is
fixed at decomposition by config plus dispatch rules and never moves because a
lane failed; a failure is the orchestrator's diagnosis job, not a
retry-at-a-different-tier job (see `loop.md` "## Failure ladder").

## Per-harness delegation

| | Claude Code (CLI + Desktop) | Codex (CLI + app) |
|---|---|---|
| Builder | Agent tool with `.claude/agents/architect-builder.md`; `disallowedTools` denies `Bash(git commit *)` and `Bash(git push *)`; `isolation: worktree`; `background: true`; model may be passed per invocation from the alias table. On the desktop app, the harness auto-creates the agent's isolation worktree (`.claude/worktrees/agent-<id>`) and its branch — integrate from that branch. On the CLI, spawns have been observed to run UNISOLATED in the orchestrator's checkout despite `isolation: worktree` frontmatter (D11) — pass isolation explicitly per invocation if supported, and never run two Claude-backend builder lanes concurrently unless each is verified to have its own worktree (`git worktree list` after spawn). In all cases, never pre-create a lane worktree for Claude-backend lanes (a pre-made one is ignored); do not use `.architect/wt/<slice>-<NN>` (that pattern is Codex-backend only, below). | `spawn_agent` with defensive framing: "Your task is: ..."; worktree created by the orchestrator via git; use `/goal` semantics for persistent lane completion. |
| Judge | Agent tool with `.claude/agents/architect-judge.md`; read-only tools plus Bash for gate commands; brain tier via `model: inherit` or per-invocation model. | Fresh `spawn_agent` with read-only instructions and the fixed judge template. |
| Monitor | Agent tool with `.claude/agents/architect-monitor.md`; cheapest tier (e.g. `claude/haiku:low`); read-only tools plus Bash/PowerShell restricted to file-growth and process-tree checks (see "## Monitor dispatch"); `background: true`; one per dispatch wave, never one per lane. | Fresh `spawn_agent` at the cheapest tier with the same detection-only instructions; counts as one of the 6 `max_threads`, same as any builder thread. |
| Parallelism | Background subagents; permission prompts surface to the main session. | Native subagents, `max_threads` 6, `max_depth` 1 (root session is depth 0; a spawned child may not spawn further — no nested orchestrators, the orchestrator dispatches builders directly), `wait_agent` for completion (the live collab event stream names the underlying tool call `wait`, not `wait_agent` — evidence: v4-codex CG4 architect-run canary `events.jsonl`). |
| Review (high-stakes) | `codex review --base` when Codex is installed; otherwise a fresh same-CLI subagent with bias caveat. | `/review` / `review_model`; Claude reviewer when installed. |
| Skill packaging | `skills/architect/` plus Claude skill install locations. | `.agents/skills/architect/SKILL.md` (and any other `skills/*/`); same source text copied by installer. |

D9 note: the desktop harness strips the Bash tool from spawned subagents by
name; both agent defs now carry `PowerShell` as the desktop-safe executor
(still padded interior per the position guard above). Lane and judge reports
must name which executor — Bash or PowerShell — ran each gate command.

D12 note: CLI subagent tool strips have also been observed intermittent and
definition-asymmetric — not the desktop's Bash-only D9 pattern. A cold
builder spawn once kept both shell tools while two same-session judge spawns
lost both and correctly returned INVALID. Working mitigation (`DESIGN.md`): a
cross-family codex judge for shell-dependent gates, plus a cold headless
`claude -p` session for any gate the codex sandbox cannot run at all. A
builder in this position records the exact missing tools and its substitute,
or reports the gate BLOCKED — never silently skips a gate or invents output.

## C5 judge delegation template

The orchestrator must send this template as-is except for replacing the three
placeholder values. It must not add slice-specific prose, encouragement,
summaries, or interpretation.

<!-- architect-judge-template:start -->
```text
Frozen gate file path: <docs/gates/<slice>.md>
Freeze commit SHA: <freeze-sha>
Branch to judge: <branch>

Verdict format:
- Gates integrity: PASS | FAIL | INVALID
  Raw evidence: <git diff <freeze-sha>..HEAD -- docs/gates/>
- Diff vs intent: PASS | FAIL | INVALID
  Raw evidence: <file:line evidence from the diff and frozen gate/spec text>
- Per gate:
  - <gate id>: PASS | FAIL | INVALID
    Command: <exact command from the frozen gate>
    Raw evidence: <verbatim stdout/stderr and exit code>
- Slice verdict: PASS | FAIL | INVALID
  Decisive reason: <one sentence tied to raw evidence>
```
<!-- architect-judge-template:end -->

## Grill delegation template

The orchestrator must send this template as-is except for replacing the two
placeholder values. It must not add slice-specific prose, encouragement,
summaries, or interpretation.

<!-- architect-grill-template:start -->
```text
Draft gate file path: <docs/gates/<slice>.md>
Branch: <branch>

Task: try to falsify this draft. Execute each gate command against the
current tree, verify every referenced path/SHA/pointer resolves, attack each
acceptance criterion for non-falsifiability and for patterns that collide
with repo realities (e.g. a grep pattern matching the repo's own name), and
flag any assumption not evidenced in the repo.

Defect report format:
- <gate id or clause>: FALSIFIED | HOLDS
  Evidence: <command run and verbatim output, or file:line>
- Assumptions not evidenced in the repo: <list or none>
```
<!-- architect-grill-template:end -->

## Codex backend from a Claude orchestrator

The worktree pre-creation and dispatch commands in this section are
Codex-backend only. Claude-backend lanes never pre-create a worktree — see
the Per-harness delegation table above.

When the orchestrator is Claude Code and the chosen brawn is Codex, write the
builder block to a file first, then pass it via stdin (`-`). Big prompt blocks
contain quotes that shells, especially Windows PowerShell, can mangle.

Single-lane slice in the current checkout, resolved brawn `codex/best`:

```bash
codex exec -C <repo-root> --sandbox workspace-write \
  -m gpt-5.5 -c model_reasoning_effort="xhigh" \
  --json -o .architect/last-run.md \
  - < .architect/dispatch-block.md
```

If the effort call resolves to `codex/tier-down`, change only the effort pin:

```bash
codex exec -C <repo-root> --sandbox workspace-write \
  -m gpt-5.5 -c model_reasoning_effort="high" \
  --json -o .architect/last-run.md \
  - < .architect/dispatch-block.md
```

For 2-4 lanes, the orchestrator owns worktree creation and parallelism:

```bash
git -C <repo-root> worktree add .architect/wt/<slice>-<NN> \
  -b lane/<slice>-<NN> <freeze-sha>

codex exec -C <repo-root>/.architect/wt/<slice>-<NN> --sandbox workspace-write \
  -m gpt-5.5 -c model_reasoning_effort="xhigh" \
  --json -o .architect/wt/<slice>-<NN>.last-run.md \
  - < .architect/wt/<slice>-<NN>.block.md
```

A worktree's `.git` is a pointer file and the resolved git dir is
sandbox-protected too. Builders cannot commit or touch shared history from any
lane; nothing reaches a branch until orchestrator checks pass.

## Integration commands

Integration is architect-only, after per-lane post-flight passes. The
`.architect/wt/<slice>-<NN>` paths below are Codex-backend only. For
Claude-backend lanes, skip `worktree add`/`worktree remove`; commit inside
the harness's auto-created worktree, then
`git -C <repo-root> merge --no-ff <agent-worktree-branch>` from the agent
worktree's branch:

```bash
git -C <repo-root> checkout -b slice/<name> <freeze-sha>
git -C <repo-root>/.architect/wt/<slice>-<NN> add -A
git -C <repo-root>/.architect/wt/<slice>-<NN> commit -m "lane <NN>: <what>"
git -C <repo-root> merge --no-ff lane/<slice>-<NN>
<run the gate commands>
git -C <repo-root> worktree remove .architect/wt/<slice>-<NN>
git -C <repo-root> branch -d lane/<slice>-<NN>
```

A merge conflict means the lane plan was not disjoint. Kill the conflicting
lane and re-spec; do not hand-resolve builder conflicts.

## Issue conventions

Claim is an orchestrator action, never a builder action: the orchestrator is
the single dispatcher and assigns exactly one issue per lane immediately
before spawning its builder. A builder never self-claims or picks its own
next issue.

```bash
gh issue edit <n> --add-assignee "@me"   # orchestrator claims, before dispatch
```

Builder comments on its own issue are limited to four kinds, never one per
commit:

- One PHASE-0 disagreements comment, before building.
- `BLOCKED: <exact blocker> + what I tried` (a blocker is a completion event).
- One milestone comment, only if the lane is long enough to warrant one.
- The final STATUS mirror (the lane report's status line, verbatim).

```bash
gh issue comment <n> --body "PHASE 0: <disagreements, or what I checked>"
gh issue comment <n> --body "BLOCKED: <exact blocker> + <what I tried>"
gh issue comment <n> --body "MILESTONE: <what completed so far>"
gh issue comment <n> --body "STATUS: <the report's exact status line>"
```

Orchestrator comments on the sub-issue: rulings, blocker answers, and the
judge verdict + decisive reason at close. The batched escalation digest goes
on the epic issue only, never on a sub-issue.

```bash
gh issue comment <n> --body "RULING: <decision> - <one line why>"
gh issue comment <n> --body "ANSWER: <blocker answer>"
gh issue comment <n> --body "VERDICT: PASS|FAIL|INVALID - <decisive reason>"
gh issue comment <epic-n> --body "DIGEST: <batched escalations + run summary>"
```

Cadence and size hold regardless of author: comments land at least 1 minute
apart, each under 65,000 characters, and never one per commit (GitHub
secondary rate limits). A running builder does NOT re-read issue comments
mid-lane — the issue is the durable log, not a channel the builder polls; an
answer reaches the builder only through a fresh respawn's spawn context (see
"## Respawn-with-answer template").

## Monitor dispatch

One detection-only monitor subagent runs alongside each dispatch wave, at the
cheapest tier (e.g. `claude/haiku:low`). It never kills, nudges, or decides;
its sweep loop and the brain's ruling options on an anomaly report are in
`loop.md` "## Monitor protocol" — this section covers only how it is
dispatched.

Inputs the orchestrator gives the monitor at dispatch: the list of in-flight
lanes (issue number, lane report path `docs/lanes/<issue-slug>-01.md`,
worktree path), any duration hints carried on the issue or gate file, and the
~10-minute sweep interval.

Monitor spawn template:

```text
You are the detection-only monitor for this dispatch wave. You never kill,
nudge, or decide - you only observe and report.

In-flight lanes:
- Issue #<n>, report <docs/lanes/<issue-slug>-01.md>, worktree <path>,
  duration hint <hint or none>.
  (one line per lane)

Every ~10 minutes, for each lane still in flight: check report/output file
growth since the last sweep (encoding-aware - Windows PowerShell writes
UTF-16), check process-tree existence/activity, and check the tail of the
output for a repeated identical command or query.

All lanes healthy -> keep looping. All lanes done -> exit quietly. Any
anomaly on any lane -> exit immediately with an evidence report: lane id,
minutes since last growth, tail excerpt, process state. Do not wait for the
other lanes to finish before reporting it.
```

Codex backend note: `max_threads` is 6. Five brawn lanes plus one monitor is
exactly at that cap — never add a sixth concurrent subagent while the
monitor is running.

## Duration hints and liveness

There are no per-command kill ceilings. Long test suites are legitimate work,
not stalls. Issue bodies and gate files may carry duration *hints* (e.g.
"full suite ~ 20m") so the monitor does not flag a lane early; a hint is
informative context for the monitor, never a ceiling anything enforces.

Liveness is judged from report/output file growth plus process-tree
activity — never from wall-clock alone:

- Silent gaps between events are normal model thinking. A low context
  reading is not wedging; harnesses auto-compact and keep going.
- A lane repeatedly issuing the same command or query with identical
  arguments is stalled even while its event/report file is still growing
  (the monitor's tail-of-output repeat-command check).
- A lane is a genuine liveness concern only once its report/output file has
  stopped growing AND the process tree shows no activity, weighed against
  any duration hint the issue or gate file carries.

On Windows PowerShell 5.1, `>`, `*>`, and `Tee-Object` write UTF-16. Liveness
and rescue checks over event files must read encoding-aware (`Get-Content`,
or `iconv` from UTF-16); byte-oriented grep can silently miss growth.

Known sandbox hang sources:

- `asyncio.create_subprocess_exec` and anything built on it: Playwright browser
  launch, anyio subprocess pools, and similar runtime harnesses. Plain
  `subprocess.run` works.
- Out-of-workspace temp paths under workspace-write. Prescribe
  `.architect/tmp/<purpose>` paths, `--basetemp .architect/tmp/<gate-id>`, and
  in-workspace cache dirs.

## Respawn-with-answer template

Respawn-over-resume is the default recovery path (D7): a fresh cold builder
spawns into the same issue's lane. Same-session resume is only for a harness
that supports live messaging while the existing session's context is still
young.

The respawn spawn block is built from four pieces:

1. The original issue body (task, boundaries, gate pointer) — unchanged.
2. The orchestrator's answer or ruling — a blocker's answer, a failure
   diagnosis, or a rescue root cause — posted as an issue comment first (the
   issue is the durable log) and copied verbatim into the spawn context (the
   spawn context is the delivery channel; a running builder does not re-read
   issue comments).
3. What the previous session completed — read from its lane report
   (`docs/lanes/<issue-slug>-01.md`) and the worktree's actual `git status` /
   `git diff`, never assumed from conversation.
4. Boundaries unchanged from the original issue: MAY TOUCH / MUST NOT TOUCH
   stay exactly as decomposed.

For a sandbox hang specifically (a wedged lane that never gets to post a
blocker comment), this rescue ladder finds the root cause before respawn:

1. Kill stuck children first. On Windows, direct child lists can lie because
   wrappers die while grandchildren hold pipes. Search system-wide by command
   signature: executable path, test path, basetemp/cache directory, or another
   unique fragment from the in-flight command.
2. If a native background subagent repeats the same hang, stop that lane and
   discard the worktree. Re-dispatch only after the issue text forbids the
   failing path or command.
3. If using the Codex backend path from Claude, resume only within the same
   lane and same issue. Put global flags before `resume`; `-C` after `resume`
   is rejected. The thread id is in the first `thread.started` event.
4. If resume fails or hangs again, discard the lane and respawn fresh from
   the frozen gate file with the root cause named as forbidden.

Rescue/respawn block template:

```text
You are resuming issue #<n>. Do not redo completed edits; working-tree edits
survived unless the following command output proves otherwise.

Previous session completed (from docs/lanes/<issue-slug>-01.md and worktree
state): <summary of file:line evidence>.

Orchestrator's answer/ruling (also posted on issue #<n>):
<answer, diagnosis, or rescue root cause>.

Observed from outside the sandbox (sandbox-hang cases only):
- <event/report file path> stopped growing at <time>.
- Last in-progress command: <exact command>.
- Stuck child processes matched: <process list or search signature>.

Required route-around:
- Run exactly: <command with in-workspace temp/cache paths>.
- Run gate commands sequentially only.
- The orchestrator reruns gates at judgment; record raw output and exact
  failures.

Boundaries remain:
- MAY TOUCH: <files>
- MUST NOT TOUCH: <files>
- Report path: docs/lanes/<issue-slug>-01.md
- End with exactly one STATUS line.
```

## Cross-model review

Use cross-model review for high-stakes slices: schema, API, persistence,
security, data loss, auth, or broad architectural changes. The reviewer's job
is to break confidence in the change with correctness, requirement, or
invariant gaps grounded in file:line evidence; no style nits.

Direction matters. In the one available study, Claude reviewing Codex output
helped, while Codex reviewing Claude output hurt. Prefer Claude-reviews-Codex
when the direction is choosable, and record the direction in the verdict
comment.

## Builder block template

```text
Execute the architect spec below. Operating rules:

PHASE 0 - Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 - The files under docs/gates/ are read-only at all times - editing
them fails the slice regardless of results.

PHASE 2 - Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. Lane
shape is ship|scout. Lane identity: you are lane <slice>-<lane>; if the spec
says you are the only builder, no other lane exists. Files outside your lane
belong outside your authority - touching them fails your lane. No placeholder
implementations - search the codebase before implementing; full
implementations only. No silent fallbacks or success-shaped defaults - never
swallow an error to make output look right. No unrequested backwards-
compatibility shims or dead compatibility code. Fail loudly, with context.
Exception: fallbacks or compat code are allowed only when the spec explicitly
requests them. Verify your work by running the lane's gate commands and
record the verbatim output. Do NOT commit - the sandbox protects .git by
design; the architect commits and merges after verification. Do NOT delete lock
files or escalate privileges if a git command fails; record the exact error and
continue.

SANDBOX EXECUTION POLICY - All temp, basetemp, and cache paths MUST be inside
the workspace (`.architect/tmp/<purpose>`); never the system temp. Run test/gate
commands SEQUENTIALLY - never two invocations in flight at once. The spec or issue may declare duration hints for known-long commands (e.g. "full suite ~ 20m");
they are context, not kill ceilings. If a command appears stalled - no output
growth and no process activity well past its duration hint - record the exact
command and observed state in the lane report and stop the lane; the monitor
and orchestrator own stall handling. A filesystem/sandbox error on a path is
environmental: record the exact failure and route around it - never retry the same path.

When a known-bad pattern exists, the spec must name it as forbidden with
evidence and provide exact command forms, flags included. Failed attempts in
prior lane reports are poisoned precedent unless explicitly marked forbidden.

When done, write your lane report to docs/lanes/<issue-slug>-01.md with RAW
results only - tables, numbers, command output - no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact. Mirror your final STATUS line as a comment on
your issue when `gh` is available; when it is not, write
"MIRROR: ORCHESTRATOR" in the report instead and continue. End the report
with exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker + what you tried).
Verdicts belong to the architect and the human. Persist until your lane is
fully handled end-to-end.

=== OBJECTIVE (and why) ===
...

=== OUTPUT FORMAT ===
...

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===
...

=== BOUNDARIES (may touch / must not touch / out of scope) ===
...

=== DISAGREEMENT RULINGS (from last session) ===
...

=== ACCEPTANCE GATES (frozen at docs/gates/<slice>.md - read-only) ===
...
```

## Builder-side standing setup

- Builders never commit; the orchestrator does. Workspace-write protects `.git`
  as read-only in Codex on Windows, including worktree pointer resolution.
- Repo `AGENTS.md`: exact build/test commands and repo gotchas only. The
  loop's PHASE rules stay in the dispatch block so they version with the skill.
- Subscription quotas are per-window plus weekly cap. For unattended runs that
  must not die mid-run, use the harness-native paid or scheduled mechanism
  rather than repo-owned loop infrastructure.
