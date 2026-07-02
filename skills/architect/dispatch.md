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
reason in the handoff.

Configured brawn CLI absent at preflight -> fall back to the tier-down default
and write one handoff line naming requested vs substituted. Cross-family review
backend absent -> run review in a fresh same-CLI context and log the
same-family bias caveat. Never hard-fail on model availability alone.

## Per-harness delegation

| | Claude Code (CLI + Desktop) | Codex (CLI + app) |
|---|---|---|
| Builder | Agent tool with `.claude/agents/architect-builder.md`; `disallowedTools` denies `Bash(git commit *)` and `Bash(git push *)`; `isolation: worktree`; `background: true`; model may be passed per invocation from the alias table. | `spawn_agent` with defensive framing: "Your task is: ..."; worktree created by the orchestrator via git; use `/goal` semantics for persistent lane completion. |
| Judge | Agent tool with `.claude/agents/architect-judge.md`; read-only tools plus Bash for gate commands; brain tier via `model: inherit` or per-invocation model. | Fresh `spawn_agent` with read-only instructions and the fixed judge template. |
| Parallelism | Background subagents; permission prompts surface to the main session. | Native subagents, `max_threads` 6, `wait_agent` for completion. |
| Review (high-stakes) | `codex review --base` when Codex is installed; otherwise a fresh same-CLI subagent with bias caveat. | `/review` / `review_model`; Claude reviewer when installed. |
| Skill packaging | `skills/architect/` plus Claude skill install locations. | `.agents/skills/architect/SKILL.md` in the later packaging slice; same source text copied by installer. |

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

## Codex backend from a Claude orchestrator

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

Integration is architect-only, after per-lane post-flight passes:

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

## Timeout policy

The slice spec declares ceilings for known commands. Use the declared ceiling;
otherwise default to 600s. Commands run sequentially. On timeout: record it;
retry once with a doubled ceiling only if output showed forward progress.
Otherwise report the stall and stop that lane.

Local Codex help checked during v3: `codex --help`, `codex exec --help`, and
`codex exec resume --help`. They exposed generic `-c key=value` overrides but
no named per-command timeout cap. Do not invent config keys. The active control
is explicit command ceilings plus heartbeat liveness.

## Stall detection and rescue

A lane is STALLED when its event/report file has not grown past its ceiling and
the last observed work is still in progress. Silent gaps between events are
normal model thinking. A low context reading is not wedging; harnesses
auto-compact and keep going.

On Windows PowerShell 5.1, `>`, `*>`, and `Tee-Object` write UTF-16. Liveness
and rescue checks over event files must read encoding-aware (`Get-Content`, or
`iconv` from UTF-16); byte-oriented grep can silently miss.

Known sandbox hang sources:

- `asyncio.create_subprocess_exec` and anything built on it: Playwright browser
  launch, anyio subprocess pools, and similar runtime harnesses. Plain
  `subprocess.run` works.
- Out-of-workspace temp paths under workspace-write. Prescribe
  `.architect/tmp/<purpose>` paths, `--basetemp .architect/tmp/<gate-id>`, and
  in-workspace cache dirs.

Rescue ladder:

1. Kill stuck children first. On Windows, direct child lists can lie because
   wrappers die while grandchildren hold pipes. Search system-wide by command
   signature: executable path, test path, basetemp/cache directory, or another
   unique fragment from the in-flight command.
2. If a native background subagent repeats the same hang, stop that lane and
   discard the worktree. Re-dispatch only after the spec forbids the failing
   path or command.
3. If using the Codex backend path from Claude, resume only within the same
   lane and same slice. Put global flags before `resume`; `-C` after `resume`
   is rejected. The thread id is in the first `thread.started` event.
4. If resume fails or hangs again, discard the lane and re-dispatch from the
   frozen spec.

Rescue block template:

```text
You are resuming the same lane. Do not redo completed edits; working-tree edits
survived unless the following command output proves otherwise.

Observed from outside the sandbox:
- <event/report file path> stopped growing at <time>.
- Last in-progress command: <exact command>.
- Stuck child processes matched: <process list or search signature>.

Verified root cause:
- <root cause>. Do not use <forbidden path/command/pattern> again.

Required route-around:
- Run exactly: <command with in-workspace temp/cache paths and timeout>.
- Run gate commands sequentially only.
- Architect will rerun gates at judgment; record raw output and exact failures.

Boundaries remain:
- MAY TOUCH: <files>
- MUST NOT TOUCH: <files>
- Report path: docs/lanes/<slice>-<lane>.md
- End with exactly one STATUS line.
```

## Cross-model review

Use cross-model review for high-stakes slices: schema, API, persistence,
security, data loss, auth, or broad architectural changes. The reviewer's job
is to break confidence in the change with correctness, requirement, or
invariant gaps grounded in file:line evidence; no style nits.

Direction matters. In the one available study, Claude reviewing Codex output
helped, while Codex reviewing Claude output hurt. Prefer Claude-reviews-Codex
when the direction is choosable, and record the direction in the handoff.

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
implementations only. Verify your work by running the lane's gate commands and
record the verbatim output. Do NOT commit - the sandbox protects .git by
design; the architect commits and merges after verification. Do NOT delete lock
files or escalate privileges if a git command fails; record the exact error and
continue.

SANDBOX EXECUTION POLICY - All temp, basetemp, and cache paths MUST be inside
the workspace (`.architect/tmp/<purpose>`); never the system temp. Run
test/gate commands SEQUENTIALLY - never two invocations in flight at once. The
spec must declare realistic timeout ceilings for known commands; 600s is only
the default for commands the spec did not declare. On timeout: record it; retry
once with a doubled ceiling ONLY if output showed forward progress, else report
it as a stall. A filesystem/sandbox error on a path is environmental: record
the exact failure and route around it - never retry the same path.

When a known-bad pattern exists, the spec must name it as forbidden with
evidence and provide exact command forms, flags included. Failed attempts in
prior lane reports are poisoned precedent unless explicitly marked forbidden.

When done, write your lane report to docs/lanes/<slice>-<lane>.md with RAW
results only - tables, numbers, command output - no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact. End it with exactly one status line:
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
