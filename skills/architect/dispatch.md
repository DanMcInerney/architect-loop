# Builder dispatch reference

## Contents

- Model alias table
- Model resolution and dispatch rules
- Per-harness delegation
- Check-runner dispatch
- CLI-launched subagent dispatch
- Preflight and postflight dispatch
- Integration commands
- Issue conventions
- Monitor dispatch
- Status display
- Duration hints and liveness
- Orchestrator shell hygiene
- Respawn-with-answer template
- Cross-model review
- Builder block template
- Builder-side standing setup

Dispatch turns a frozen slice or high-judgment stage into fresh strategist, builder, or verification work.
The orchestrator chooses the job shape, model role, worktree, and report path; the subagent receives a self-contained task and returns raw evidence.

Verified local Codex facts from the v3 evidence remain useful for the Codex
backend path: the model slug is `gpt-5.5`; `--search` and
`-a/--ask-for-approval` are top-level `codex --help` flags, not `codex exec`
flags; `codex exec` is non-interactive; Goal Mode subcommands are bare
`/goal`, `/goal pause|resume|clear`.

## Model alias table

| Alias | Flags | Notes |
|---|---|---|
| `codex/best` | `-m gpt-5.5 -c model_reasoning_effort="xhigh"` | Frontier Codex row. Watch for a possible gpt-5.6 rollout before changing this pin. |
| `claude/best` | `--model fable --effort high` | Frontier Claude row (Fable 5 at high effort). If Fable is unavailable on the account, pin `--model opus --effort xhigh` (Opus 4.8) and record the substitution on the tracking issue. |
| `codex/tier-down` | `-m gpt-5.5 -c model_reasoning_effort="high"` | Effort-down on the frontier model; high is the quota-saving tier-down, not a model downgrade. Watch the codex rows per model generation. |
| `claude/tier-down` | `--model sonnet --effort high` | Model-down at high effort. |

General tier-down rule: same family, one step down. For Claude, the step is the
model at high effort (Fable/Opus -> Sonnet; Sonnet -> Haiku only when the
orchestrator explicitly chooses that risk). For Codex, the step is effort
(xhigh -> high) on the frontier model. Dispatch blocks print explicit pinned
flags in every command; this table is the source of those pins.

## Model resolution and dispatch rules

Role strings are `<cli>/<model-spec>[:<effort>]`, with `<cli>` in `{claude,codex}`.
The orchestrator is not a config role: it is the Claude or Codex session already running the loop.
Configurable roles resolve repo `.architect/config`, then user `~/.architect/config`, then defaults: `strategist = claude/best` (Fable 5 high) for `/architect` high-judgment subagents, and `builders = codex/best` (gpt-5.5 xhigh, Fast pins below) as codex-CLI jobs.
Claude Code and Codex orchestrators both dispatch builders through the codex command lines in the sections below.
The Claude-native builder backend (`builders = claude/tier-down`, Sonnet high, Agent-tool jobs; `architect-builder` preloads `tdd` and `codebase-design`) is the config-selected alternative and codex-absent fallback.
Flat `key = value` lines are the supported role-key format; the legacy orchestrator key is retired, warns, and is ignored. Unknown keys warn and never fail.

A pin is a request, not proof — verify the served model from the spawn transcript's model field; resume drifts a subagent's model back to the parent's, and `CLAUDE_CODE_SUBAGENT_MODEL` outranks per-invocation pins.

Optional dispatch-rules lines route task classes to a builder tier:

```ini
# .architect/config or ~/.architect/config
strategist = claude/best # Fable subagents for design/review
builders = codex/best # GPT-5.5 xhigh builders; Fast pins under ChatGPT auth
tracker = markdown # local issue files; omit for github default
when trivial mechanical edit -> codex/best:xhigh # keep builder pin
when broad ambiguous refactor -> codex/best:xhigh # same builder pin, record why
```

Format: `when <task-class description> -> <cli>/<model-spec>[:<effort>] # why`.
The trailing reason is optional but preferred. Absent role lines use `strategist = claude/best` and `builders = codex/best`; absent dispatch rules = the builders default.
A matching rule is still a judgment aid; the orchestrator records which rule was used and may override it with a reason recorded on the issue.

Builder speed default: when the resolved builders backend is Codex under
ChatGPT auth, every builder `codex exec` appends the Fast-mode pins
`-c service_tier="fast" -c features.fast_mode=true` — same model, faster
inference (gpt-5.5 at 2.5x credit burn), never a tier change. Verify at the
intake canary; API-key auth cannot use Fast mode — drop the two pins and
record the substitution on the tracking issue (no silent fallback). The
default is builder-only; strategist subagents, verification subagents, and the
monitor never carry the Fast pins.

Strategist *model* unavailable on the account -> step down in-family per the alias row (e.g. Fable -> Opus xhigh) and record the substitution.
Strategist *CLI* absent at preflight -> run the strategist on the orchestrator's own family at the alias table's frontier row, without builder Fast pins, and record the capability caveat; never silently skip a strategist stage.
Configured builders CLI absent -> fall back to `claude/tier-down` and write one tracking-issue comment naming requested vs substituted.
Cross-family review backend absent -> run review in a fresh same-CLI context and log the same-family bias caveat. Never hard-fail on model availability alone.
Builder tier is fixed at decomposition by config plus dispatch rules and never moves because a job failed; failure is the orchestrator's diagnosis job, not a retry-at-a-different-tier job (see `loop.md` "## Failure ladder").

## Per-harness delegation

| | Claude Code (CLI + Desktop) | Codex (CLI + app) |
|---|---|---|
| Strategist | Resolved `strategist = claude/*`: Agent tool at the strategist model, `run_in_background: false` for result-bearing stages, stage skills named in the prompt (`codebase-design` plus `to-spec`, `to-issues`, `frozen-checks`, `adversarial-review`, or `final-review`). Resolved `strategist = codex/*` (cross-family, e.g. gpt-5.5 under a Claude Code orchestrator): background `codex exec -o <file>` job launched through `run-job.ps1|.sh` like any CLI subagent — read-heavy sandbox, never builder Fast pins; drafts and the verdict line return as files (the sandbox has no tracker access). | Resolved `strategist = codex/*`: `spawn_agent` with defensive framing at the strategist model, never builder Fast pins. Resolved `strategist = claude/*` (the default Fable row, cross-family): CLI-launched `claude -p` through `run-job.ps1|.sh` with the dispatch block on stdin and a file-based output contract; claude CLI absent -> record the substitution and run the strategist on Codex per the fallback rule above. |
| Builder | Agent tool with `.claude/agents/architect-builder.md`; `disallowedTools` denies `Bash(git commit *)` and `Bash(git push *)`; `isolation: worktree`; `background: true`; model may be passed per invocation from the alias table. On the desktop app, the harness auto-creates the agent's isolation worktree (`.claude/worktrees/agent-<id>`) and its branch — integrate from that branch. On the CLI, spawns have been observed to run UNISOLATED in the orchestrator's checkout despite `isolation: worktree` frontmatter (D11) — pass isolation explicitly per invocation if supported, and never run two Claude-backend builder jobs concurrently unless each is verified to have its own worktree (`git worktree list` after spawn). In all cases, never pre-create a job worktree for Claude-backend jobs (a pre-made one is ignored); do not use `.architect/wt/<run>/<slice>-<NN>` (that pattern is Codex-backend only, below). | `spawn_agent` with defensive framing: "Your task is: ..."; worktree created by the orchestrator via git; use `/goal` semantics for persistent job completion. |
| Verification (optional, read-only) | Agent tool with `.claude/agents/architect-judge.md` (read-only verification def); dispatch synchronously with `run_in_background: false`, but require a report file plus one greppable verdict line and harvest that file; read-only tools plus Bash for check commands; the resolved builders model passed per invocation (the def's `model: inherit` is only the fallback where per-invocation model is unsupported). | Background `codex exec -o <file>` typed-exit path with read-only instructions; the process exit wakes the loop. |
| Monitor | Script watchdog (`watchdog.ps1` on Windows, `watchdog.sh` on POSIX) under a long-lived Bash task when the orchestrator can wait on task exit; LLM fallback template only otherwise. | Script watchdog (`watchdog.ps1` on Windows, `watchdog.sh` on POSIX) under a long-lived Bash task when task exits wake the orchestrator; LLM fallback template only otherwise and it consumes one native subagent slot. |
| Parallelism | CLI-launched builder backends, including Claude Code orchestrating Codex, run up to 10 background jobs. Claude Agent-tool builders are harness-native: use the harness cap (currently 5), verify isolated worktrees before concurrent spawns, and expect permission prompts in the main session. | CLI-launched builder backends run up to 10 background jobs. Native `spawn_agent` builders use the harness cap (currently 5), `max_depth` 1 (root session is depth 0; a spawned child may not spawn further), and `wait_agent` for completion (the live collab event stream names the underlying tool call `wait`, not `wait_agent`). |
| Review (high-stakes) | `codex review --base` when Codex is installed; otherwise a fresh same-CLI subagent with bias caveat. | `/review` / `review_model`; Claude reviewer when installed. |
| Skill packaging | `skills/architect/` plus Claude skill install locations. | `.agents/skills/architect/SKILL.md` (and any other `skills/*/`); same source text copied by installer. |

Any Claude-native Agent-tool dispatch, backgrounded or synchronous, must name a report path and one greppable verdict line; the orchestrator harvests that artifact, while a delivered final message is only an optimization. If the harness goes idle without the file, use `loop.md`'s one-poke-then-respawn ladder.

D9 note: the desktop harness strips the Bash tool from spawned subagents by
name; both agent defs now carry `PowerShell` as the desktop-safe executor
(still padded interior per the position guard above). Job and verification reports
must name which executor — Bash or PowerShell — ran each check command.

D12 note: CLI subagent tool strips have also been observed intermittent and
definition-asymmetric — not the desktop's Bash-only D9 pattern. A fresh
builder spawn once kept both shell tools while two same-session judge spawns
lost both and correctly returned INVALID. Working mitigation (`DESIGN.md`): a
cross-family codex judge for shell-dependent checks, plus a fresh headless
`claude -p` session for any check the codex sandbox cannot run at all. A
builder in this position records the exact missing tools and its substitute,
or reports the check BLOCKED — never silently skips a check or invents output.

## Check-runner dispatch

Graded RUN grammar is normative from the shipped s1 runner in `skills/architect/check-runner.ps1`: first backtick span is the command; expectation begins immediately after the closing backtick as ``-> exit:<n>`` with optional `match:"<substring>"`. `match:` is a fixed, case-sensitive stdout substring check, never regex. Text after the expectation is judge-facing prose; non-RUN items are judge-only. A RUN item without an expectation exits 5 with `CHECKRUN: ERROR missing RUN expectation`, and no partial evidence is kept.
Example line: ``- RUN: `git grep -F -c "needle" -- path/to/file.md` -> exit:0 match:"needle"``

Evidence contains per-item `expected:`/`verdict:` lines, then `CHECKRUN SUMMARY: run_items=<n> pass=<n> fail=<n>`; typed exits: 0 all pass, 2 any fail, 5 error with no partial evidence.
Launch pattern: write the runner config JSON — fields `check_file`, `workdir`, `freeze_sha`, `evidence_out`, `executor` (`powershell`|`bash`), `max_output_lines` (default 60) — then run `skills/architect/check-runner.ps1 -Config <path>` or `check-runner.sh <path>` as a foreground child of a long-lived Bash task; on exit 0 commit `docs/jobs/<run>/<issue-slug>-checkrun.md`, then merge through postflight. Exit 2 routes to the failure ladder; `loop.md` owns the full rule.

Long RUN output keeps head, tail, and any pytest short-summary block; optional `progress_out` writes flushed `RUN_START`/`RUN_END`/`RUNNER_ERROR` sidecar events for forensics only.

## CLI-launched subagent dispatch

Worktree pre-creation and `codex exec` are Codex-backend builder jobs even under Claude Code; Claude-backend harness jobs use the Per-harness delegation table.

All long-lived CLI subagents — builders, cross-family strategists, verification jobs — run through `run-job.ps1|.sh`; the wrapper writes `job.meta.json`, `job.heartbeat`, `job.exit.json`, and `events.jsonl`, including `pgid` on POSIX or `job_object` on Windows for `kill-job.ps1|.sh`. It accepts an opaque command, so the child can be `codex exec`, `claude -p`, or a long check-runner under a Claude Code or Codex orchestrator. Never pipe live stdout through display filters such as `tail`; the wrapper owns redirection. Every dispatch event re-arms the watchdog over all in-flight CLI jobs.

Single Codex-backed job:

```bash
<repo-root>/skills/architect/run-job.sh --job-dir <repo-root>/.architect/jobs/<run>/<slice>-<NN> --workdir <repo-root>/.architect/wt/<run>/<slice>-<NN> --backend codex-cli --report-path <repo-root>/docs/jobs/<run>/<slice>-01.md --stdin-file <repo-root>/.architect/jobs/<run>/<slice>-<NN>/block.md --sandbox-env -- \
  codex exec -C <repo-root>/.architect/wt/<run>/<slice>-<NN> --sandbox workspace-write -m gpt-5.5 -c model_reasoning_effort="xhigh" -c service_tier="fast" -c features.fast_mode=true --json -o <repo-root>/.architect/jobs/<run>/<slice>-<NN>/last-run.md \
  -
```

Claude-CLI-backed jobs use the same wrapper and change only the child:

```bash
<repo-root>/skills/architect/run-job.sh --job-dir <repo-root>/.architect/jobs/<run>/<slice>-<NN> --workdir <repo-root>/.architect/wt/<run>/<slice>-<NN> --backend claude-cli --report-path <repo-root>/docs/jobs/<run>/<slice>-01.md --stdin-file <repo-root>/.architect/jobs/<run>/<slice>-<NN>/block.md -- \
  claude -p --model fable --effort high --output-format stream-json --verbose
```

PowerShell uses `-ArgvJson` so child argv stays opaque:

```powershell
$argv = @("claude","-p","--model","fable","--effort","high","--output-format","stream-json","--verbose") | ConvertTo-Json -Compress
& <repo-root>\skills\architect\run-job.ps1 -JobDir <repo-root>\.architect\jobs\<run>\<slice>-<NN> -Workdir <repo-root>\.architect\wt\<run>\<slice>-<NN> -Backend claude-cli -ReportPath <repo-root>\docs\jobs\<run>\<slice>-01.md -StdinFile <repo-root>\.architect\jobs\<run>\<slice>-<NN>\block.md -ArgvJson $argv
```

For 2-10 CLI-launched jobs, the orchestrator owns worktree creation and parallelism:

```bash
git -C <repo-root> worktree add <repo-root>/.architect/wt/<run>/<slice>-<NN> -b job/<run>/<slice>-<NN> <freeze-sha>
<repo-root>/skills/architect/run-job.sh ... -- <codex-or-claude command for that worktree>
```

A worktree's `.git` is a pointer file and the resolved git dir is
sandbox-protected too. Builders cannot commit or touch shared history from any
job; nothing reaches a branch until orchestrator checks pass.

## Preflight and postflight dispatch

Default dispatch and integration are script-backed. The orchestrator writes one
config JSON, runs the platform script, and rules on the typed line.

Preflight worktree creation is the Codex-backend path only. Claude-backend jobs
never pre-create worktrees; use the harness-created worktree and branch from
the Per-harness delegation table instead.

preflight config JSON:

```json
{
  "repo_root": "<abs path>",
  "freeze_sha": "<sha>",
  "worktree": ".architect/wt/<run>/<slice>-<NN>",
  "job_branch": "job/<run>/<slice>-<NN>",
  "require_files": ["docs/checks/<run>/<slice>.md"]
}
```

postflight config JSON:

```json
{
  "repo_root": "<abs path>",
  "factory_branch": "factory/<run>",
  "job_branch": "job/<run>/<slice>-<NN>",
  "freeze_sha": "<sha>",
  "may_touch": ["skills/architect/preflight.ps1", "tests/fixtures/orchscripts/"],
  "exempt": ["docs/jobs/<run>/"],
  "merge_message": "<text>",
  "push": false,
  "remote": "origin",
  "worktree": ".architect/wt/<run>/<slice>-<NN>"
}
```

Typed exits:

| Script | Exit | Prefix | Meaning |
|---|---:|---|---|
| preflight | 0 | `PREFLIGHT: OK` | worktree exists, HEAD equals `freeze_sha`, and every `require_files` path exists |
| preflight | 5 | `PREFLIGHT: FAIL` | setup could not complete; record the line and fall back to the recorded manual sequence |
| postflight | 0 | `POSTFLIGHT: OK` | touch-set audit, merge, optional push, and cleanup completed; may append `cleanup=deferred <path>` |
| postflight | 2 | `POSTFLIGHT: VIOLATION` | automatic FAIL evidence for the job; do not merge |
| postflight | 3 | `POSTFLIGHT: CONFLICT` | decomposition failure: kill the conflicting job and re-spec, per the existing rule |
| postflight | 5 | `POSTFLIGHT: ERROR` | script/config/git error; abort partial merge state, then fall back to the recorded manual sequence |

The scripts never post to the tracker, never grade, and never resolve
conflicts. A postflight exit 5 is the only typed path that routes to the
manual integration fallback below; exit 2 and exit 3 are rulings, not fallback
requests.

## Integration commands

Integration is architect-only, after per-job postflight passes. The default
path is `postflight.ps1` or `postflight.sh` from `## Preflight and postflight
dispatch`; it performs the touch-set audit, merge, optional push, and cleanup
from the config. The manual sequence below is the recorded fallback for exit 5
or an environment where the script cannot run. The `.architect/wt/<run>/<slice>-<NN>`
paths below are Codex-backend only. For Claude-backend jobs, skip `worktree
add`/`worktree remove`; commit inside the harness's auto-created worktree, then
`git -C <repo-root> merge --no-ff <agent-worktree-branch>` from the agent
worktree's branch.

Recorded fallback manual sequence:

```bash
git -C <repo-root> checkout -b slice/<name> <freeze-sha>
git -C <repo-root>/.architect/wt/<run>/<slice>-<NN> add -A
git -C <repo-root>/.architect/wt/<run>/<slice>-<NN> commit -m "job <NN>: <what>"
git -C <repo-root> merge --no-ff job/<run>/<slice>-<NN>
<run the check commands>
git -C <repo-root> worktree remove .architect/wt/<run>/<slice>-<NN>
git -C <repo-root> branch -d job/<run>/<slice>-<NN>
```

A merge conflict means the job plan was not disjoint. Kill the conflicting
job and re-spec; do not hand-resolve builder conflicts.

## Issue conventions

In markdown mode, every command below maps to an orchestrator file operation; see `tracker.md` `## Command mapping`.

Every run issue body ends with `<!-- architect-run: <run> -->`. A sub-issue
under the run parent with the wrong author or missing run marker is never
dispatched; escalate it on the tracking-issue digest.

In github mode, create sub-issues with native edges:
`gh issue create --title <t> --body-file <f> --parent <tracking-n> --blocked-by <n,n>`.
Parent and blocker edges recorded only as body or title text are retired for
github mode; the status emitter reads `--json parent,blockedBy`.

Claim is an orchestrator action, never a builder action: the orchestrator is
the single dispatcher and assigns exactly one issue per job before spawning.
A builder never self-claims or picks its own next issue.

On current backends, builders usually cannot post to issues: Codex has no
network, and Claude subagents have a shell-strip watch item. `MIRROR:
ORCHESTRATOR` is normal; direct builder posting stays permitted where supported.

```bash
gh issue edit <n> --add-assignee "@me"   # orchestrator claims, before dispatch
```

Builder comments on its own issue are limited to four kinds, never one per
commit:

- One PHASE-0 disagreements comment, before building.
- `BLOCKED: <exact blocker> + what I tried` (a blocker is a completion event).
- One milestone comment, only if the job is long enough to warrant one.
- The final STATUS mirror (the job report's status line, verbatim).

```bash
gh issue comment <n> --body "PHASE 0: <disagreements, or what I checked>"
gh issue comment <n> --body "BLOCKED: <exact blocker> + <what I tried>"
gh issue comment <n> --body "MILESTONE: <what completed so far>"
gh issue comment <n> --body "STATUS: <the report's exact status line>"
```

Orchestrator comments on the sub-issue: rulings, blocker answers, and the
checkrun result + decisive reason at close. The final review's verdict plus
fix-issue list and the batched escalation digest go on the tracking issue
only. The reviewer's dispatch block cites the installed user-level
`final-review` skill text by explicit path, never the repo or worktree copy.
When a recorded ruling replaces a checkrun, append `GRADED-BY-RULING:` to `docs/jobs/<run>/<issue-slug>-rulings.md`; `ground.ps1|.sh` treats that report as graded.
On findings, the orchestrator harvests the review spec, fix-issue drafts, and
check drafts out of the reviewer worktree before discarding it, commits them
as the fix-wave freeze, and updates the tracking-issue body's freeze record
to the latest freeze SHA (prior SHAs stay in comments). Fix-issue dispatch
reuses the builder block template below — no new machinery.

```bash
gh issue comment <n> --body "RULING: <decision> - <one line why>"
gh issue comment <n> --body "ANSWER: <blocker answer>"
gh issue comment <n> --body "CHECKRUN: exit <0|2> <CHECKRUN SUMMARY line> | POSTFLIGHT: <line> - <decisive reason>"
gh issue comment <tracking-issue-n> --body "REVIEW: GREEN" # or "REVIEW: FINDINGS n=<count> - <fix-issue list>"
gh issue comment <tracking-issue-n> --body "DIGEST: <batched escalations + run summary>"
```

Cadence and size hold regardless of author: comments land at least 1 minute
apart, each under 65,000 characters, and never one per commit (host-side
secondary rate limits). A running builder does NOT re-read issue comments
mid-job — the issue is the durable log, not a channel the builder polls; an
answer reaches the builder only through a fresh respawn's spawn context (see
"Respawn-with-answer template").

## Monitor dispatch

Every dispatch event re-arms the watchdog: initial wave, job END
recompute-and-dispatch, blocker respawn, and fix-wave dispatch. The
orchestrator writes a fresh config covering every in-flight CLI-launched
builder/subagent from either a Claude Code or Codex orchestrator, then launches
the platform script as a foreground child of a long-lived Bash task:
`watchdog.ps1` on Windows, `watchdog.sh` on POSIX. The config uses the spec's
Interface contract:

```json
{
  "sweep_sec": 120,
  "stall_after_min": 10,
  "jobs": [
    { "id": "issue-31", "job_dir": "<path>", "events_file": "<path>",
      "report_path": "<path>", "worktree": "<path>", "duration_hint_min": 0 }
  ]
}
```
Codex jobs may set `rollout_glob` to override the default `~/.codex/sessions/*/*/*/rollout-*<thread_id>*.jsonl` derivation.

The watchdog detects mechanically; the orchestrator supplies the reasoning.
The watchdog never kills, nudges, or judges. It exits with typed evidence:

| Exit | Prefix | Meaning |
|---|---|---|
| 0 | `WATCHDOG: ALL_DONE` | every job report exists, with path and byte size evidence |
| 2 | `WATCHDOG: INTEGRATED` | a job worktree or events file vanished because the orchestrator integrated it mid-sweep |
| 3 | `WATCHDOG: STALL` | wrapper heartbeat is fresh but event/report growth stopped beyond `stall_after_min` plus any duration hint |
| 4 | `WATCHDOG: REPEAT` | the last four parsed command events were identical and need an intentional-vs-stuck ruling |
| 5 | `WATCHDOG: ERROR` | watchdog config is missing or unreadable |
| 6 | `WATCHDOG: REPORT_READY` | terminal `STATUS:` exists, `job.exit.json` is absent, and the wrapper heartbeat is stale |
| 7 | `WATCHDOG: ORPHANED` | wrapper heartbeat is stale but event/report output still grows |
| 8 | `WATCHDOG: DEAD` | wrapper heartbeat is stale and no event/report output is growing |
| 9 | `WATCHDOG: DONE_FAILED` | child exited nonzero, or exited 0 without terminal `STATUS:` |
| 10 | `WATCHDOG: LEGACY_UNWRAPPED` | job lacks wrapper metadata and cannot provide deterministic exit truth |
| 11 | `WATCHDOG: BLOCKED_ON_TOOL` | heartbeat is fresh, output is stalled, and the freshest stream ends at a started tool/function call with no result |

Use the LLM fallback only for backends where the orchestrator cannot launch or
wait on a long-lived Bash task whose exit wakes the loop.

## Status display

`skills/architect/status.ps1 [<run-slug>] [-RepoRoot <path>]` (Windows) and
`skills/architect/status.sh [<run-slug>] [--repo-root <path>]` (POSIX) read
only run artifacts plus tracker state; the first positional is always a run
slug.
Piped output is plain text by design; callers print it verbatim instead of hand-composing status.

<!-- architect-monitor-fallback-template:start -->
```text
You are the detection-only fallback monitor for this dispatch wave. Use this
template only when the backend cannot wake the orchestrator from a background
watchdog process exit. You never kill, nudge, or decide - you only observe and
report evidence.

In-flight jobs:
- Issue #<n>, events <path>, report <docs/jobs/<run>/<issue-slug>-01.md>,
  worktree <path>, duration hint <hint or none>.
  (one line per job)

Sweep every ~10 minutes. For each job, check events/report byte growth,
worktree file mtimes, and repeated identical commands in the tail. A quiet
events file on a single sweep is normal model thinking, not a stall.

Quiet exit is allowed ONLY when, for every job, you list the report path and
byte size as evidence. If a worktree or events file vanished because the
orchestrator integrated the job mid-sweep, exit `INTEGRATED_BY_ORCHESTRATOR`
and list the vanished path. If you cannot verify something from this sandbox,
state what you cannot verify instead of assuming the job is done.

Any stall, wedged tool call, or repeat concern exits immediately with the job id, minutes since last file activity, byte/mtime evidence, repeated or wedged command if present, and tail excerpt. Do not wait for other jobs to finish before reporting it.
```
<!-- architect-monitor-fallback-template:end -->

Native harness note: built-in subagents cap at 5 concurrent jobs. CLI-launched
`codex exec`/`claude -p` style jobs cap at 10 and do not consume native
subagent slots; if an LLM fallback monitor is running in native-harness mode,
reserve one slot.

## Duration hints and liveness

There are no per-command kill ceilings. Long test suites are legitimate work,
not stalls. Issue bodies and check files may carry duration *hints* (e.g.
"full suite ~ 20m") so the monitor does not flag a job early; a hint is
informative context for the monitor, never a ceiling anything enforces.

Builder edits, orchestrator exercises: spawn-heavy checks that cannot run in the sandbox are named as orchestrator-side bounded RUN evidence; the builder performs edits plus static/local verification only.

Sanctioned substitutions:

Executor truth for sandboxed jobs: MSYS2/Cygwin-runtime binaries (Git for
Windows `bash.exe`, `usr/bin/grep.exe`, `sed.exe`) die at startup under the
Codex Windows sandbox because Cygwin's named shared-memory `CreateFileMapping`
is denied with Win32 error 5 under the sandbox's dedicated-user restricted
token. Native `git.exe` and PowerShell are unaffected; POSIX/macOS/Linux
sandboxes are unaffected. Known upstream: openai/codex#12000 and
openai/codex#21715. Therefore check files name the platform-native executor
primary for sandboxed jobs: PowerShell + native git subcommands on Windows,
bash on POSIX; the recorded same-pattern substitution rule stays for
everything else.

| Condition | Substitution | Provenance |
|---|---|---|
| Git Bash CreateFileMapping Win32 error 5 in Codex Windows sandbox | PowerShell + native git same-pattern, recorded per check | evidence: factory-hardening research, git history |
| `uv` AppData cache denial (os error 5) | `UV_CACHE_DIR=.architect/tmp/uv-cache`, recorded | evidence: uv-cache sandbox redirect, git history |
| pytest tmpdir `mkdir(mode=0o700)` WinError 5 in Codex Windows sandbox | wrapper `--sandbox-env` TEMP/TMP/TMPDIR redirect | evidence: pair-fairness-webui-2026-07 probes |
| Tracker posting unavailable in sandbox | `MIRROR: ORCHESTRATOR` in the report | evidence: subagent shell-strip codex fallback, git history |

## Orchestrator shell hygiene

Use absolute paths in every orchestrator shell command. Write dispatch,
verification, and config blocks with file tools, never heredocs. Never rely on a
persisted cwd across commands; run #30 lost three commands to current-directory
drift before this rule was written down.

Liveness is judged from wrapper-owned files, never cross-session process
enumeration. On Windows under Claude Code, launch long-lived CLI jobs through
its Bash wrapper when available; the PowerShell wrapper exists for harnesses
where Bash is stripped.

- `DONE_OK` requires `job.exit.json` exit 0 AND a report whose final nonblank line starts with `STATUS:`; every other child exit is `DONE_FAILED`; terminal-looking report text never outranks a fresh wrapper heartbeat.
- `job.state.json` persists growth clocks across watchdog re-arms.
- A job repeatedly issuing the same command or query with identical
  arguments is stalled even while its event/report file is still growing
  (the monitor's tail-of-output repeat-command check).
- Stale heartbeat plus growing output is `ORPHANED`, not `DEAD`; the
  orchestrator rules from artifacts.
- The PowerShell wrapper redirects stdout live to `events.jsonl` and appends
  stderr when the child exits; use the Bash wrapper when live merged stderr is
  required for diagnosis.

On Windows PowerShell 5.1, `>`, `*>`, and `Tee-Object` write UTF-16. Liveness
and rescue checks over event files must read encoding-aware (`Get-Content`,
or `iconv` from UTF-16); byte-oriented grep can silently miss growth.

Known sandbox hang sources:

- `asyncio.create_subprocess_exec` and anything built on it: Playwright browser
  launch, anyio subprocess pools, and similar runtime harnesses. Plain
  `subprocess.run` works.
- Out-of-workspace temp paths under workspace-write. Prescribe
  `.architect/tmp/<purpose>` paths, `--basetemp .architect/tmp/<check-id>`, and
  in-workspace cache dirs.

## Respawn-with-answer template

Respawn-over-resume is the default recovery path (D7): a fresh builder
spawns into the same issue's job. Same-session resume is only for a harness
that supports live messaging while the existing session's context is still
young.

The respawn spawn block is built from four pieces:

1. The original issue body (task, boundaries, check pointer) — unchanged.
2. The orchestrator's answer or ruling — a blocker's answer, a failure
   diagnosis, or a rescue root cause — posted as an issue comment first (the
   issue is the durable log) and copied verbatim into the spawn context (the
   spawn context is the delivery channel; a running builder does not re-read
   issue comments).
3. What the previous session completed — read from its job report
   (`docs/jobs/<run>/<issue-slug>-01.md`) and the worktree's actual `git status` /
   `git diff`, never assumed from conversation.
4. Boundaries unchanged from the original issue: MAY TOUCH / MUST NOT TOUCH
   stay exactly as decomposed.

For a sandbox hang specifically (a wedged job that never gets to post a
blocker comment), this rescue ladder finds the root cause before respawn:

1. Kill stuck wrapped jobs first with `kill-job.ps1|.sh <job-dir>`; it reads `job.meta.json`, terminates the recorded `pgid`/`job_object`, and waits for wrapper exit truth.
2. If a native background subagent repeats the same hang, stop that job and
   discard the worktree. Re-dispatch only after the issue text forbids the
   failing path or command.
3. If using the Codex backend path from Claude, resume only within the same
   job and same issue. Put global flags before `resume`; `-C` after `resume`
   is rejected. The thread id is in the first `thread.started` event.
4. If resume fails or hangs again, discard the job and respawn fresh from
   the frozen check file with the root cause named as forbidden.

Rescue/respawn block template:

```text
You are resuming issue #<n>. Do not redo completed edits; working-tree edits
survived unless the following command output proves otherwise.

Previous session completed (from docs/jobs/<run>/<issue-slug>-01.md and worktree
state): <summary of file:line evidence>.

Orchestrator's answer/ruling (also posted on issue #<n>):
<answer, diagnosis, or rescue root cause>.

Observed from outside the sandbox (sandbox-hang cases only):
- <event/report file path> stopped growing at <time>.
- Last in-progress command: <exact command>.
- Stuck child processes matched: <process list or search signature>.

Required route-around:
- Run exactly: <command with in-workspace temp/cache paths>.
- Run check commands sequentially only.
- The orchestrator reruns checks at judgment; record raw output and exact
  failures.

Boundaries remain:
- MAY TOUCH: <files>
- MUST NOT TOUCH: <files>
- Report path: docs/jobs/<run>/<issue-slug>-01.md
- The literal string `STATUS:` must not appear anywhere until the job is fully complete; never initialize a placeholder STATUS line.
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

FIRST ACTION - run `bash skills/architect/ffcheck.sh <dispatch-head-sha>`
(PowerShell: `powershell -File skills/architect/ffcheck.ps1 <dispatch-head-sha>`)
from the worktree root and rule on its typed exit before any other step: 0
`FFCHECK: OK` proceed, 2 `FFCHECK: DIVERGED` stop and report, 5
`FFCHECK: ERROR` stop and report.

PHASE 0 - Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 - The files under docs/checks/ are read-only at all times - editing
them fails the slice regardless of results.

PHASE 2 - Build YOUR JOB ONLY: exactly the files listed in BOUNDARIES. Job shape is ship.
Job identity: you are job <run>/<slice>-<NN>; if the spec
says you are the only builder, no other job exists. Files outside your job
belong outside your authority - touching them fails your job. No placeholder
implementations - search the codebase before implementing; full
implementations only. No silent fallbacks or success-shaped defaults - never
swallow an error to make output look right. No unrequested backwards-
compatibility shims or dead compatibility code. Fail loudly, with context.
Exception: fallbacks or compat code are allowed only when the spec explicitly
requests them. Verify your work by running the job's check commands and
record the verbatim output. Do NOT commit - the sandbox protects .git by
design; the architect commits and merges after verification. Do NOT delete lock
files or escalate privileges if a git command fails; record the exact error and
continue.

SANDBOX EXECUTION POLICY - All temp, basetemp, and cache paths MUST be inside
the workspace (`.architect/tmp/<purpose>`); never the system temp. Run test/check
commands SEQUENTIALLY - never two invocations in flight at once. The spec or issue may declare duration hints for known-long commands (e.g. "full suite ~ 20m");
they are context, not kill ceilings. If a command appears stalled - no output
growth and no file mtime movement well past its duration hint - record the
exact command and observed state in the job report and stop the job; the
monitor and orchestrator own stall handling. A filesystem/sandbox error on a path is
environmental: record the exact failure and route around it - never retry the same path.

When a known-bad pattern exists, the spec must name it as forbidden with
evidence and provide exact command forms, flags included. Failed attempts in
prior job reports are poisoned precedent unless explicitly marked forbidden.

When done, write your job report to docs/jobs/<run>/<issue-slug>-01.md with RAW
results only - tables, numbers, command output - no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact. Mirror your final STATUS line as a comment on
your issue when tracker posting is available; when it is not, write
"MIRROR: ORCHESTRATOR" in the report instead and continue. End the report
with exactly one status line. The literal string `STATUS:` must not appear anywhere in the report until the job is fully complete; never initialize a placeholder STATUS line.
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker + what you tried).
Verdicts belong to the architect and the human. Persist until your job is
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

=== ACCEPTANCE CHECKS (frozen at docs/checks/<run>/<slice>.md - read-only) ===
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
