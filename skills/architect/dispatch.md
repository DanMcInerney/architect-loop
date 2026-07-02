# Builder dispatch reference

Verified live against Codex CLI 0.139.0 on this Windows machine. Facts that
correct common misinformation: the model slug is `gpt-5.5` (not
`gpt-5.5-codex`); `--search` and `-a/--ask-for-approval` appear on top-level
`codex --help` but are not `codex exec` flags; `codex exec` is
non-interactive by design and the sandbox flag is the permission control.
Goal Mode's real subcommands are bare `/goal`, `/goal pause|resume|clear`.

**Preflight (once per environment):** run `codex --version`. Need >= 0.133.
On the first dispatch in a new environment, launch one canary run and confirm
it starts cleanly before fanning anything out; CLI flags churn between
versions.

## Model alias table

| Alias | Flags | Notes |
|---|---|---|
| `codex/best` | `-m gpt-5.5 -c model_reasoning_effort="xhigh"` | Frontier Codex row. Watch for a possible gpt-5.6 rollout before changing this pin. |
| `claude/best` | `--model opus --effort xhigh` | Best Claude Code judgment/build row. |
| `codex/tier-down` | `-m gpt-5.5 -c model_reasoning_effort="high"` | Effort-down on the frontier model; high is the quota-saving tier-down, not a model downgrade. Watch the codex rows per model generation. |
| `claude/tier-down` | `--model sonnet --effort high` | Model-down at high effort. |

General tier-down rule: same family, one step down. For Claude, the step is the
model at high effort (Fable/Opus -> Sonnet; Sonnet -> Haiku when the architect
explicitly chooses that risk). For Codex, the step is effort (xhigh -> high) on
the frontier model. Dispatch blocks still print explicit pinned flags in every
command; this table is the source of those pins.

## Model resolution and degradation

Role strings are `<cli>/<model-spec>[:<effort>]`, with `<cli>` in `{claude,
codex}`. Resolution order per role is repo `.architect/config`, then user
`~/.architect/config`, then defaults: brain = the running session; brawn =
tier-down per the alias table. Flat `key = value` config lines are the only
supported format; unknown keys warn and never fail.

Configured brawn CLI absent at preflight -> fall back to the tier-down default
and write one handoff line naming requested vs substituted. Cross-family review
backend absent -> run review in a fresh same-CLI context and log the same-family
bias caveat. Never hard-fail on model availability alone.

Every dispatch block header states resolved brawn as cli/model/effort. The
handoff Session log records Brain and Brawn. The loop driver logs the brain per
iteration. A run's models must be reconstructable from repo evidence.

## Builder backends

A brawn backend must provide all of: headless one-shot prompt input;
per-run model and effort flags; unattended permission control; JSONL event
stream plus final-message-to-file for liveness checks; worktree compatibility.

Only these backends are supported:

| Backend | Template | Boundary |
|---|---|---|
| Codex | `codex exec -C <worktree> --sandbox workspace-write <model flags> --json -o <last-message> - < <block.md>` | Canonical builder. Workspace-write protects `.git`, including worktree git-dir resolution. |
| Claude Code | `claude -p --model <x> --effort <y> --output-format stream-json --verbose --permission-mode dontAsk --allowedTools "Read" "Edit" "Write" "Bash(<gate commands>:*)" "Bash(git status:*)" "Bash(git diff:*)" --disallowedTools "Bash(git commit *)" "Bash(git push *)"` | F12 rationale: dontAsk continues with denials; allowlist omits commit; deny rules are an extra no-commit guard. Keep the post-flight `git log <freeze-sha>..HEAD` and branch-state detection backstop. |

Lane identity (Claude Code lanes): when a Claude-backend lane's
`stream-json` output is redirected to a workspace file, the dispatch block MUST
name that file as the lane's own event stream and state the lane is the only
builder when true. Evidence: 2026-07-02 live canary, where a lane found its own
event file plus the architect's "lane 01 in flight" sentinel, inferred a
duplicate worker, and exited with zero artifacts.

On Windows PowerShell 5.1, `>`, `*>`, and `Tee-Object` write UTF-16. Liveness
and rescue checks over event files must read encoding-aware (`Get-Content`, or
`iconv` from UTF-16); byte-oriented grep can silently miss.

Excluded runtimes are deliberate scope, not TODO scaffolding. opencode is
policy-viable but outside the 2026-07-02 Claude+Codex product scope; gemini and
pi cannot enforce unattended no-commit natively; agy flag syntax was
unverified. Revisit in `DESIGN.md` only when new evidence changes that matrix.

## Canonical headless dispatch (architect-driven)

Write the builder block to a file first, then pass it via stdin (`-`) - never
as a shell argument. Big prompt blocks contain quotes that shells, especially
Windows PowerShell, mangle; a mangled argument can make codex wait on stdin and
hang forever in a background shell.

Single-lane slice in the main checkout, resolved brawn `codex/best`:

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

## Worktree fan-out (2-4 lanes - the architect owns parallelism)

One isolated worktree plus one fresh builder session per lane, all launched in
parallel in the background by the architect. Lanes have file-touch sets checked
for overlap from the spec; each writes raw results to its own
`docs/lanes/<slice>-<lane>.md`, so nothing collides.

```bash
# per lane, off the freeze commit
git -C <repo-root> worktree add .architect/wt/<slice>-<NN> \
  -b lane/<slice>-<NN> <freeze-sha>

# write the lane's builder block, then dispatch
codex exec -C <repo-root>/.architect/wt/<slice>-<NN> --sandbox workspace-write \
  -m gpt-5.5 -c model_reasoning_effort="xhigh" \
  --json -o .architect/wt/<slice>-<NN>.last-run.md \
  - < .architect/wt/<slice>-<NN>.block.md
```

A worktree's `.git` is a pointer file and the resolved git dir is
sandbox-protected too. Builders cannot commit or touch shared history from any
lane; nothing reaches a branch until architect checks pass.

### Integration (architect-only, after per-lane post-flight passes)

```bash
git -C <repo-root> checkout -b slice/<name> <freeze-sha>
# per passing lane, sequentially:
git -C <repo-root>/.architect/wt/<slice>-<NN> add -A
git -C <repo-root>/.architect/wt/<slice>-<NN> commit -m "lane <NN>: <what>"
git -C <repo-root> merge --no-ff lane/<slice>-<NN>
<run the gate commands>
# cleanup:
git -C <repo-root> worktree remove .architect/wt/<slice>-<NN>
git -C <repo-root> branch -d lane/<slice>-<NN>
```

A merge conflict means the lane plan was not disjoint. Kill the conflicting
lane and re-spec; do not hand-resolve builder conflicts.

Dispatch notes:

- Run builders in the background; read `.architect/last-run.md`, event JSONL,
  and repo state afterwards.
- Pin the model explicitly from `## Model alias table`; automations have been
  reported silently falling back to older models.
- Same-slice follow-up after a human ruling: `codex exec resume --last
  "<rulings + proceed>"`. Never resume across slices.
- Optional: `--output-schema <schema.json>` to force a machine-checkable final
  report.
- Cross-model review gate: `codex review --base <branch>` or
  `codex review --uncommitted`, with custom focus text appended.
- Add `.architect/` to the repo's `.gitignore`.
- **Builders never commit - the architect does.** Workspace-write protects
  `.git` as read-only (verified on Windows, Codex 0.139.0; no config toggle;
  `writable_roots` does not bypass it; worktree pointer files are resolved and
  protected too).

## Timeout cap investigation

Local help checked for this slice: `codex --help`, `codex exec --help`, and
`codex exec resume --help`. They expose generic `-c key=value` config override
but no named per-command timeout cap. The offline config reference was not
available from this sandbox, so do not assert a hard cap from memory or invent
`-c` keys. The gap is owned: the builder block's graduated timeout policy is
the active control, and loop WAIT liveness bounds true stalls.

The live CLI also confirms the rescue gotcha: flags such as `-C` and
`--sandbox` parse before `resume` (`codex exec -C . --sandbox workspace-write
resume --help`) and `codex exec resume -C . --help` rejects `-C`.

## Stall detection and rescue (verified live: Windows, Codex 0.139.0)

A dispatched run is STALLED when its `--json` event file has not grown for
15+ minutes and the last event is an `in_progress` command_execution. Silent
gaps between events are normal model thinking; a shell command that should take
seconds sitting in flight for 15+ minutes is not.

Known sandbox hang sources:

- `asyncio.create_subprocess_exec` and anything built on it: Playwright browser
  launch, anyio subprocess pools, and similar runtime harnesses. Plain
  `subprocess.run` works.
- Out-of-workspace temp paths (`C:\tmp`, `$env:TEMP`, pytest `--basetemp` or
  `-o cache_dir` outside the repo) under workspace-write: sometimes instant
  `PermissionError`, sometimes a hot spin after tests complete. Verified
  signature: uniform ~46%-core burn across unrelated pytest runs on
  2026-07-01. Treat any out-of-root write path as a hang source, not an error
  source. Prescribe `--basetemp .architect/tmp/<gate-id> -p no:cacheprovider`
  or an equivalent in-workspace cache path.

Rescue ladder:

1. Kill stuck children first. On Windows, the direct child list can lie because
   wrappers die while grandchildren hold pipes. Search system-wide by command
   signature: executable path, test path, basetemp/cache directory, or other
   unique fragments from the in-flight command. Expect codex to wake within
   seconds after pipes close.
2. If the builder re-enters the same hang, kill the codex run and resume the
   thread with `codex exec [flags] resume <thread-id> - < rescue-block.md`.
   Put global flags before `resume`; `-C` after `resume` is rejected. The
   thread id is in the first `thread.started` event.
3. If resume fails or hangs again, discard the lane and re-dispatch from the
   frozen spec (hard rule 7).

Rescue block template:

```text
You are resuming the same lane. Do not redo completed edits; working-tree edits
survived unless the following command output proves otherwise.

Observed from outside the sandbox:
- <event file path> stopped growing at <time>.
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

## Manual alternative (human-driven)

Paste the builder block into an interactive `codex` session prefixed with
`/goal `. Codex loops plan -> act -> test -> review against the stopping
condition until done. Use when the human wants to watch or steer the run.

## Builder block template

```text
Execute the architect spec below. Operating rules:

PHASE 0 - Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 - Freeze shared contracts (schemas/interfaces) in docs/ first. After
freeze they are read-only for everyone including you. The files under
docs/gates/ are read-only at all times - editing them fails the slice
regardless of results.

PHASE 2 - Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents - touching them fails your lane.
No placeholder implementations - search the codebase before implementing;
full implementations only. Verify your work by running the lane's gate
commands and record the verbatim output. Do NOT commit - the sandbox protects
.git by design; the architect commits and merges after verification. Do NOT
delete lock files or escalate privileges if a git command fails; record the
exact error and continue.

SANDBOX EXECUTION POLICY - All temp, basetemp, and cache paths MUST be inside
the workspace (`.architect/tmp/<purpose>`); never the system temp, never
`C:\tmp`. Run test/gate commands SEQUENTIALLY - never two invocations in flight
at once. The spec must declare realistic timeout ceilings for known commands;
600s is only the default for commands the spec did not declare. On timeout:
record it; retry once with a doubled ceiling ONLY if output showed forward
progress, else report it as a stall. A filesystem/sandbox error on a path is
environmental: record the exact failure and route around it - never retry the
same path.

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

## Builder-side standing setup (one time per machine/repo)

- `~/.codex/config.toml`: `model = "gpt-5.5"`. Parallelism is
  architect-orchestrated worktrees; it does not depend on Codex's experimental
  `[features] multi_agent` config.
- Repo `AGENTS.md`: exact build/test commands and repo gotchas only. The
  loop's PHASE rules stay in the dispatch block so they version with the skill.
- Subscription quotas are per-5h window plus weekly cap; long runs draw the
  weekly pool. For overnight unattended runs that must not die mid-run,
  `CODEX_API_KEY` per-token billing avoids window exhaustion.
