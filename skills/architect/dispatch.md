# Builder dispatch reference

## Contents

- Model alias table
- Model resolution and dispatch rules
- Per-harness delegation
- Check-runner dispatch
- CLI-launched subagent dispatch
- Sandbox posture
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

Dispatch turns a frozen slice or high-judgment stage into fresh strategist,
builder, or verification work: the orchestrator chooses job shape, model
role, worktree, and report path; the subagent gets a self-contained task and
returns raw evidence.

Verified Codex facts: the model slug is `gpt-5.5`; `--search` and
`-a/--ask-for-approval` are top-level `codex --help` flags, not `codex exec`
flags; `codex exec` is non-interactive; Goal Mode subcommands are bare
`/goal`, `/goal pause|resume|clear`.

## Model alias table

| Alias | Flags | Notes |
|---|---|---|
| `codex/best` | `-m gpt-5.5 -c model_reasoning_effort="xhigh"` | Frontier Codex row; watch for a gpt-5.6 rollout before changing the pin. |
| `claude/best` | `--model fable --effort high` | Frontier Claude row. If Fable is unavailable, pin `--model opus --effort xhigh` and record the substitution. |
| `codex/tier-down` | `-m gpt-5.5 -c model_reasoning_effort="high"` | Effort-down on the frontier model, not a model downgrade. |
| `claude/tier-down` | `--model sonnet --effort high` | Model-down at high effort. |

Tier-down rule: same family, one step down — Claude steps the model
(Fable/Opus -> Sonnet; Sonnet -> Haiku only as an explicit orchestrator
risk), Codex steps effort (xhigh -> high). Dispatch blocks print explicit
pinned flags in every command; this table is the source of those pins.

## Model resolution and dispatch rules

Role strings are `<cli>/<model-spec>[:<effort>]`, `<cli>` in
`{claude,codex}`. The orchestrator is not a config role — it is the session
running the loop. Roles resolve repo `.architect/config`, then
`~/.architect/config`, then defaults `strategist = claude/best` and
`builders = codex/best`. Flat `key = value` lines only; unknown keys warn
and never fail. A pin is a request, not proof — verify the served model
from the spawn transcript; resume drifts a subagent's model back to the
parent's, and `CLAUDE_CODE_SUBAGENT_MODEL` outranks per-invocation pins.

```ini
# .architect/config or ~/.architect/config
strategist = claude/best # Fable subagents for design/review
builders = codex/best # GPT-5.5 xhigh builders; Fast pins under ChatGPT auth
tracker = markdown # local issue files; omit for github default
when trivial mechanical edit -> codex/best:xhigh # keep builder pin
when broad ambiguous refactor -> codex/best:xhigh # same builder pin, record why
```

Dispatch-rules lines (`when <task-class> -> <cli>/<model-spec>[:<effort>] #
why`) route task classes to a builder tier; a matching rule is a judgment
aid — record which rule was used, and any override with a reason.

Builder speed default: Codex builders under ChatGPT auth append the
Fast-mode pins `-c service_tier="fast" -c features.fast_mode=true` — same
model, faster inference; verify at the intake canary. API-key auth cannot
use Fast mode — drop the pins and record the substitution. Builder-only:
strategist, verification, and monitor never carry Fast pins.

Fallbacks, each recorded, never silent: strategist model unavailable ->
step down in-family per the alias row. Strategist CLI absent -> run the
strategist on the orchestrator's own family at the frontier row; never skip
a strategist stage. Builders CLI absent -> `claude/tier-down` plus one
tracking-issue comment naming requested vs substituted. Cross-family review
backend absent -> fresh same-CLI review with the bias caveat logged. Never
hard-fail on model availability alone. Builder tier is fixed at
decomposition and never moves because a job failed (`loop.md`
"## Failure ladder").

## Per-harness delegation

| | Claude Code (CLI + Desktop) | Codex (CLI + app) |
|---|---|---|
| Strategist | `strategist = claude/*`: Agent tool at the strategist model, `run_in_background: false` for result-bearing stages, stage skills named in the prompt. `strategist = codex/*`: background `codex exec -o <file>` job through `run-job.ps1\|.sh` — same full-access posture, no Fast pins; drafts and verdict return as files. | `strategist = codex/*`: `spawn_agent` with defensive framing, no Fast pins. `strategist = claude/*`: CLI-launched `claude -p` through `run-job.ps1\|.sh`, dispatch block on stdin, file-based output contract; claude CLI absent -> record and fall back per the rules above. |
| Builder | Agent tool with `.claude/agents/architect-builder.md`; `isolation: worktree`; `background: true`; model passed per invocation. Desktop auto-creates the isolation worktree (`.claude/worktrees/agent-<id>`) — integrate from its branch. CLI spawns have run UNISOLATED despite frontmatter (D11): pass isolation per invocation if supported and verify each concurrent job's worktree (`git worktree list`) before running two at once. Never pre-create a worktree for Claude-backend jobs; `.architect/wt/<run>/<slice>-<NN>` is Codex-backend only. | `spawn_agent` with defensive framing ("Your task is: ..."); worktree created by the orchestrator via git; `/goal` semantics for persistent completion. |
| Verification (optional, read-only) | Agent tool with `.claude/agents/architect-judge.md`, `run_in_background: false`, report file plus one greppable verdict line required; builders model per invocation. | Background `codex exec -o <file>` typed-exit path with read-only instructions; process exit wakes the loop. |
| Monitor | Script watchdog (`watchdog.ps1` / `watchdog.sh`) under a long-lived Bash task; LLM fallback template only where task exits cannot wake the loop. | Same; the LLM fallback consumes one native subagent slot. |
| Parallelism | CLI-launched builder backends run up to 10 background jobs. Agent-tool builders use the harness cap (5); verify isolated worktrees before concurrent spawns. | CLI jobs cap 10. Native `spawn_agent` uses the harness cap (5), `max_depth` 1, `wait_agent` for completion. |
| Review (high-stakes) | `codex review --base` when installed; else a fresh same-CLI subagent with bias caveat. | `/review` / `review_model`; Claude reviewer when installed. |
| Skill packaging | `skills/architect/` plus Claude skill install locations. | `.agents/skills/architect/SKILL.md`; same source copied by installer. |

Any Claude Agent-tool dispatch must name a report path and one greppable
verdict line; the orchestrator harvests that artifact — a delivered final
message is only an optimization. If the harness goes idle without the file,
use loop.md's one-poke-then-respawn ladder.

D9: the desktop harness strips Bash from spawned subagents by name; both
agent defs carry `PowerShell` as the desktop-safe executor (padded interior
per the position guard). Reports must name which executor ran each check.
D12: CLI tool strips are intermittent and definition-asymmetric; mitigation
is a cross-family codex judge for shell-dependent checks plus a fresh
headless `claude -p` session for checks the codex sandbox cannot run. A
builder in this position records the missing tools and its substitute, or
reports the check BLOCKED — never silently skips or invents output.

## Check-runner dispatch

Graded RUN grammar is normative from `skills/architect/check-runner.ps1`:
first backtick span is the command; expectation follows immediately as
``-> exit:<n>`` with optional `match:"<substring>"` — a fixed,
case-sensitive stdout substring, never regex. Text after the expectation is
judge-facing prose; non-RUN items are judge-only. A RUN item without an
expectation exits 5 with `CHECKRUN: ERROR missing RUN expectation`, no
partial evidence kept.
Example: ``- RUN: `git grep -F -c "needle" -- path/to/file.md` -> exit:0 match:"needle"``

Evidence: per-item `expected:`/`verdict:` lines, then `CHECKRUN SUMMARY:
run_items=<n> pass=<n> fail=<n>`; typed exits 0 all pass, 2 any fail, 5
error. Launch: write the runner config JSON — `check_file`, `workdir`,
`freeze_sha`, `evidence_out`, `executor` (`powershell`|`bash`),
`max_output_lines` (default 60) — then run
`skills/architect/check-runner.ps1 -Config <path>` or `check-runner.sh
<path>` as a foreground child of a long-lived Bash task. Exit 0: commit
`docs/jobs/<run>/<issue-slug>-checkrun.md`, merge through postflight; exit
2: failure ladder (`loop.md`). Long RUN output keeps head, tail, and any
pytest short-summary block; optional `progress_out` writes
`RUN_START`/`RUN_END`/`RUNNER_ERROR` sidecar events for forensics only.

## CLI-launched subagent dispatch

Worktree pre-creation and `codex exec` are Codex-backend builder jobs even
under Claude Code; Claude-backend harness jobs use the Per-harness table.

All long-lived CLI subagents — builders, cross-family strategists,
verification jobs — run through `run-job.ps1|.sh`; the wrapper writes
`job.meta.json`, `job.heartbeat`, `job.exit.json`, `events.jsonl`, and
`stderr.log`, including `pgid` on POSIX or `job_object` on Windows for
`kill-job.ps1|.sh`. It accepts an opaque command, so the child can be
`codex exec`, `claude -p`, or a long check-runner under a
Claude Code or Codex orchestrator. Never pipe live stdout through filters; the
wrapper owns redirection. Every dispatch event re-arms the watchdog over
all in-flight CLI jobs.

Single Codex-backed job:

```bash
<repo-root>/skills/architect/run-job.sh --job-dir <repo-root>/.architect/jobs/<run>/<slice>-<NN> --workdir <repo-root>/.architect/wt/<run>/<slice>-<NN> --backend codex-cli --report-path <repo-root>/docs/jobs/<run>/<slice>-01.md --stdin-file <repo-root>/.architect/jobs/<run>/<slice>-<NN>/block.md -- \
  codex exec -C <repo-root>/.architect/wt/<run>/<slice>-<NN> --sandbox danger-full-access -m gpt-5.5 -c model_reasoning_effort="xhigh" -c service_tier="fast" -c features.fast_mode=true --json -o <repo-root>/.architect/jobs/<run>/<slice>-<NN>/last-run.md \
  -
```

Claude-CLI-backed jobs change only the child:

```bash
<repo-root>/skills/architect/run-job.sh --job-dir <repo-root>/.architect/jobs/<run>/<slice>-<NN> --workdir <repo-root>/.architect/wt/<run>/<slice>-<NN> --backend claude-cli --report-path <repo-root>/docs/jobs/<run>/<slice>-01.md --stdin-file <repo-root>/.architect/jobs/<run>/<slice>-<NN>/block.md -- \
  claude -p --model fable --effort high --output-format stream-json --verbose
```

PowerShell uses `-ArgvJson` so child argv stays opaque:

```powershell
$argv = @("claude","-p","--model","fable","--effort","high","--output-format","stream-json","--verbose") | ConvertTo-Json -Compress
& <repo-root>\skills\architect\run-job.ps1 -JobDir <repo-root>\.architect\jobs\<run>\<slice>-<NN> -Workdir <repo-root>\.architect\wt\<run>\<slice>-<NN> -Backend claude-cli -ReportPath <repo-root>\docs\jobs\<run>\<slice>-01.md -StdinFile <repo-root>\.architect\jobs\<run>\<slice>-<NN>\block.md -ArgvJson $argv
```

For 2-10 CLI jobs the orchestrator owns worktree creation and parallelism:

```bash
git -C <repo-root> worktree add <repo-root>/.architect/wt/<run>/<slice>-<NN> -b job/<run>/<slice>-<NN> <freeze-sha>
<repo-root>/skills/architect/run-job.sh ... -- <codex-or-claude command for that worktree>
```

Builders still never commit — a prose ban audited by postflight; nothing
reaches a branch until orchestrator checks pass.

## Sandbox posture

Builder, strategist, and verification CLI jobs run `--sandbox
danger-full-access` by design (owner directive, 2026-07-07): network
calls, reads, and writes outside the worktree are allowed. Three verified
hang classes forced this — the Codex Windows sandbox's restricted token
wedged jobs after the real work had already succeeded: (1) Cygwin-runtime
binaries (Git-for-Windows bash/grep/sed) die at startup
(`CreateFileMapping` Win32 error 5; openai/codex#12000, #21715); (2)
pytest's cacheprovider hangs forever in `pytest_sessionfinish ->
tempfile.mkdtemp()` (py-spy-verified stack; TEMP/TMP/TMPDIR + `--basetemp`
+ `-o cache_dir` redirects verified insufficient); (3) network I/O under
the token blocks or is rejected — asyncio `select()` hangs on
live-provider calls, a spawned web server never comes up so the builder's
readiness poll waits forever, and network-shaped commands can be
`rejected: blocked by policy` outright. `Start-Process` itself is not a
trigger (controlled repro 2026-07-07: detached spawn returns promptly
under both modes; server spawn + local HTTP round trip returns 200 only
under full access). Researchers stay `--sandbox read-only`
(`research.md`); they write nothing.

The constraints that matter are enforced downstream, not by the OS
sandbox: builders never commit (prose ban, postflight-audited); MAY TOUCH
is enforced by postflight's touch-set diff over the full freeze->job
range; a `docs/checks/` edit is an automatic FAIL; and unwrapped work
cannot merge (postflight `job_dir` gate below).

Opting a job back into a sandbox (not recommended): every pytest
invocation needs `-p no:cacheprovider`; pass the wrapper's `--sandbox-env`
flag to redirect TEMP/TMP/TMPDIR into the workspace; keep temp/cache paths
in `.architect/tmp/<purpose>`; sanctioned same-pattern substitutions
(PowerShell + native git for Cygwin deaths,
`UV_CACHE_DIR=.architect/tmp/uv-cache`) are recorded per use; and the hang
classes above still apply to anything this list misses.

## Preflight and postflight dispatch

Script-backed by default: write one config JSON, run the platform script,
rule on the typed line. Preflight worktree creation is Codex-backend only —
Claude-backend jobs use the harness-created worktree from the Per-harness
table.

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
  "worktree": ".architect/wt/<run>/<slice>-<NN>",
  "job_dir": ".architect/jobs/<run>/<slice>-<NN>"
}
```

`job_dir` is mandatory for CLI-launched jobs: postflight requires
`<job_dir>/job.exit.json` (wrapper exit truth) and exits
`POSTFLIGHT: VIOLATION wrapper exit truth missing` without it — unwrapped
work cannot merge. Omit `job_dir` only for harness-native Agent-tool jobs,
whose exits the harness itself owns.

| Script | Exit | Prefix | Meaning |
|---|---:|---|---|
| preflight | 0 | `PREFLIGHT: OK` | worktree exists, HEAD equals `freeze_sha`, every `require_files` path exists |
| preflight | 5 | `PREFLIGHT: FAIL` | record the line; use the manual fallback |
| postflight | 0 | `POSTFLIGHT: OK` | audit, merge, optional push, cleanup done; may append `cleanup=deferred <path>` |
| postflight | 2 | `POSTFLIGHT: VIOLATION` | automatic FAIL evidence; do not merge |
| postflight | 3 | `POSTFLIGHT: CONFLICT` | decomposition failure: kill and re-spec |
| postflight | 5 | `POSTFLIGHT: ERROR` | abort partial merge state; manual fallback |

The scripts never post to the tracker, never grade, never resolve
conflicts. Only exit 5 routes to the manual fallback; 2 and 3 are rulings.

## Integration commands

Architect-only, after per-job postflight passes; the default path is
`postflight.ps1|.sh`. The manual sequence below is the recorded fallback
for exit 5 or an environment where the script cannot run. The
`.architect/wt/` paths are Codex-backend only; for Claude-backend jobs skip
`worktree add`/`remove`, commit inside the harness worktree, then
`git -C <repo-root> merge --no-ff <agent-worktree-branch>`.

```bash
git -C <repo-root> checkout -b slice/<name> <freeze-sha>
git -C <repo-root>/.architect/wt/<run>/<slice>-<NN> add -A
git -C <repo-root>/.architect/wt/<run>/<slice>-<NN> commit -m "job <NN>: <what>"
git -C <repo-root> merge --no-ff job/<run>/<slice>-<NN>
<run the check commands>
git -C <repo-root> worktree remove .architect/wt/<run>/<slice>-<NN>
git -C <repo-root> branch -d job/<run>/<slice>-<NN>
```

A merge conflict means the plan was not disjoint: kill the conflicting job
and re-spec; do not hand-resolve.

## Issue conventions

In markdown mode every command below maps to an orchestrator file operation
(`tracker.md` `## Command mapping`).

Every run issue body ends with `<!-- architect-run: <run> -->`. A sub-issue
under the run parent with the wrong author or missing marker is never
dispatched; escalate it on the digest.

Github mode creates sub-issues with native edges:
`gh issue create --title <t> --body-file <f> --parent <tracking-n>
--blocked-by <n,n>`. Body/title-only edge text is retired; the status
emitter reads `--json parent,blockedBy`.

Claim is an orchestrator action — one issue per job, assigned before
spawning; a builder never self-claims:

```bash
gh issue edit <n> --add-assignee "@me"   # orchestrator claims, before dispatch
```

Builders often lack tracker auth in their jobs — `MIRROR: ORCHESTRATOR` is
normal. Builder comments on its own issue are exactly four kinds, never
one per commit:

```bash
gh issue comment <n> --body "PHASE 0: <execution conflicts, or what I checked>"
gh issue comment <n> --body "BLOCKED: <exact blocker> + <what I tried>"
gh issue comment <n> --body "MILESTONE: <what completed so far>"
gh issue comment <n> --body "STATUS: <the report's exact status line>"
```

Orchestrator comments: rulings, blocker answers, checkrun result + decisive
reason at close on the sub-issue; the review verdict and batched digest on
the tracking issue only. The reviewer's dispatch block cites the installed
user-level `final-review` skill text by explicit path. When a recorded
ruling replaces a checkrun, append `GRADED-BY-RULING:` to the rulings file.
Fix-issue dispatch reuses the builder block template — no new machinery.

```bash
gh issue comment <n> --body "RULING: <decision> - <one line why>"
gh issue comment <n> --body "ANSWER: <blocker answer>"
gh issue comment <n> --body "CHECKRUN: exit <0|2> <CHECKRUN SUMMARY line> | POSTFLIGHT: <line> - <decisive reason>"
gh issue comment <tracking-issue-n> --body "REVIEW: GREEN" # or "REVIEW: FINDINGS n=<count> - <fix-issue list>"
gh issue comment <tracking-issue-n> --body "DIGEST: <batched escalations + run summary>"
```

Cadence: comments at least 1 minute apart, under 65,000 characters
(host-side rate limits). A running builder does NOT re-read issue comments
mid-job; answers arrive only through a fresh respawn's spawn context.

## Monitor dispatch

Every dispatch event re-arms the watchdog: initial wave, job END
recompute-and-dispatch, blocker respawn, fix-wave dispatch. Write a fresh
config covering every in-flight CLI-launched job, then launch the platform
script (`watchdog.ps1` / `watchdog.sh`) as a foreground child of a
long-lived Bash task:

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

Codex jobs may set `rollout_glob` to override the default
`~/.codex/sessions/*/*/*/rollout-*<thread_id>*.jsonl` derivation. The
watchdog detects mechanically — never kills, nudges, or judges — and exits
typed:

| Exit | Prefix | Meaning |
|---|---|---|
| 0 | `WATCHDOG: ALL_DONE` | every job report exists, with path and byte size |
| 2 | `WATCHDOG: INTEGRATED` | a worktree/events file vanished via mid-sweep integration |
| 3 | `WATCHDOG: STALL` | heartbeat fresh but growth stopped past `stall_after_min` + hint |
| 4 | `WATCHDOG: REPEAT` | last four parsed command events identical |
| 5 | `WATCHDOG: ERROR` | config missing or unreadable |
| 6 | `WATCHDOG: REPORT_READY` | terminal `STATUS:` exists, exit truth absent, heartbeat stale |
| 7 | `WATCHDOG: ORPHANED` | heartbeat stale but output still grows |
| 8 | `WATCHDOG: DEAD` | heartbeat stale, nothing growing, no terminal report |
| 9 | `WATCHDOG: DONE_FAILED` | child exited nonzero, or 0 without terminal `STATUS:` |
| 10 | `WATCHDOG: LEGACY_UNWRAPPED` | no wrapper metadata; no deterministic exit truth |
| 11 | `WATCHDOG: BLOCKED_ON_TOOL` | heartbeat fresh, output stalled, stream ends at a started tool call |

Use the LLM fallback only where the orchestrator cannot wait on a
long-lived Bash task exit:

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

Native harness note: built-in subagents cap at 5; CLI-launched jobs cap at
10 and consume no native slots. An LLM fallback monitor in native-harness
mode reserves one slot.

## Status display

`skills/architect/status.ps1 [<run-slug>] [-RepoRoot <path>]` and
`skills/architect/status.sh [<run-slug>] [--repo-root <path>]` read only
run artifacts plus tracker state; the first positional is always a run
slug. Output is plain text by design; print it verbatim, never
hand-compose status.

## Duration hints and liveness

No per-command kill ceilings: long test suites are legitimate work. Issue
bodies and check files may carry duration *hints* (e.g. "full suite ~ 20m")
— informative context for the monitor, never an enforced ceiling.

Builder edits, orchestrator exercises: spawn-heavy checks that cannot run
in the job's environment become orchestrator-side bounded RUN evidence;
the builder does edits plus static/local verification only.

## Orchestrator shell hygiene

Absolute paths in every orchestrator shell command. Write dispatch,
verification, and config blocks with file tools, never heredocs. Never rely
on a persisted cwd across commands.

Liveness is judged from wrapper-owned files, never cross-session process
enumeration. On Windows under Claude Code, launch long-lived CLI jobs
through its Bash wrapper when available; the PowerShell wrapper exists for
harnesses where Bash is stripped.

- `DONE_OK` requires `job.exit.json` exit 0 AND a report whose final
  nonblank line starts with `STATUS:`; every other child exit is
  `DONE_FAILED`. Terminal-looking report text never outranks a fresh
  wrapper heartbeat.
- `job.state.json` persists growth clocks across watchdog re-arms.
- A job repeating the same command with identical arguments is stalled even
  while output grows.
- Stale heartbeat plus growing output is `ORPHANED`, not `DEAD`; rule from
  artifacts.
- Wrappers write child stdout to `events.jsonl` and stderr to `stderr.log`;
  growth counts both, repeat-command checks stay stdout-only, `DONE_FAILED`
  diagnosis reads `stderr.log` directly.

On Windows PowerShell 5.1, `>`, `*>`, and `Tee-Object` write UTF-16; read
event files encoding-aware (`Get-Content`, or `iconv`) — byte-oriented grep
can silently miss growth.

## Respawn-with-answer template

Respawn-over-resume is the default recovery (D7): a fresh builder spawns
into the same issue's job. Resume only where the harness supports live
messaging and the session context is still young. The respawn block has
four pieces:

1. The original issue body — unchanged.
2. The orchestrator's answer or ruling, posted as an issue comment first
   and copied verbatim into the spawn context (the only delivery channel).
3. What the previous session completed — from its job report and the
   worktree's actual `git status`/`git diff`, never assumed.
4. Boundaries exactly as decomposed: MAY TOUCH / MUST NOT TOUCH unchanged.

Sandbox-hang rescue ladder, before respawn:

1. Kill stuck wrapped jobs with `kill-job.ps1|.sh <job-dir>`; it reads
   `job.meta.json`, terminates the recorded `pgid`/`job_object`, and waits
   for wrapper exit truth.
2. A native background subagent repeating the same hang: stop it, discard
   the worktree, re-dispatch only after the issue text forbids the failing
   path or command.
3. Codex-backend resume: only within the same job and issue; global flags
   before `resume` (`-C` after is rejected); thread id is in the first
   `thread.started` event.
4. If resume fails or hangs again, discard and respawn fresh from the
   frozen check with the root cause named as forbidden.

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

For high-stakes slices (schema, API, persistence, security, data loss,
auth, broad architecture): a reviewer whose job is to break confidence with
correctness, requirement, or invariant gaps grounded in file:line evidence
— no style nits. Direction matters: the one available study found
Claude-reviews-Codex helped and the reverse hurt; prefer that direction and
record it in the verdict comment.

## Builder block template

```text
Execute the architect spec below. Operating rules:

FIRST ACTION - run `bash skills/architect/ffcheck.sh <dispatch-head-sha>`
(PowerShell: `powershell -File skills/architect/ffcheck.ps1 <dispatch-head-sha>`)
from the worktree root and rule on its typed exit before any other step: 0
`FFCHECK: OK` proceed, 2 `FFCHECK: DIVERGED` stop and report, 5
`FFCHECK: ERROR` stop and report.

PHASE 0 - Before any code: reply with your plan and any execution conflict
with this slice's spec, checks, boundaries, or live dependencies. Cite real
repo file:line evidence or command output. Include nonexistent APIs,
dependency/version mismatches, impossible check expectations, stale paths,
and boundary conflicts. Silent compliance is a failure. Silent scope additions
are a failure. If you find no conflicts, state what files, APIs, and commands
you checked before concluding the slice is executable. Do not relitigate
product/design preferences or add scope. Verify named APIs/formats/versions
against the live dependencies before planning around them.

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

EXECUTION POLICY - Run test/check commands SEQUENTIALLY - never two
invocations in flight at once. Prefer in-workspace scratch paths
(`.architect/tmp/<purpose>`) so forensics stay with the job. The spec or issue may declare duration hints for known-long commands (e.g. "full suite ~ 20m");
they are context, not kill ceilings. If a command appears stalled - no output
growth and no file mtime movement well past its duration hint - record the
exact command and observed state in the job report and stop the job; the
monitor and orchestrator own stall handling. A filesystem or permission error on a path is
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

- Builders never commit; the orchestrator does. Enforcement is the prose
  ban plus postflight — the touch-set audit over the full freeze->job
  range and the `job_dir` wrapper gate — since the OS sandbox is
  deliberately weak (`## Sandbox posture`).
- Repo `AGENTS.md` carries exact build/test commands and repo gotchas only;
  the loop's PHASE rules stay in the dispatch block so they version with
  the skill.
- Unattended runs that must not die mid-run use the harness-native paid or
  scheduled mechanism, not repo-owned loop infrastructure (subscription
  quotas are per-window plus weekly cap).
