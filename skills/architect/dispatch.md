# Builder Dispatch Reference

## Contents

- Model alias table
- Storage contract
- Gate grammar and check-runner
- Judge templates
- Scout and stress-test templates
- Canonical headless dispatch
- Post-flight checks
- Patch bundle finalization
- Watchdog dispatch
- Stall detection and rescue
- Builder block template

Dispatch turns a frozen local slice into fresh builder, scout, judge, or
research work. The architect chooses the job shape, effort, worktree, and
report paths; workers return raw evidence only.

Verified Codex facts from upstream remain load-bearing: the model slug is
`gpt-5.5`; `--search` and `-a/--ask-for-approval` are not `codex exec` flags;
`codex exec` is non-interactive; prompt blocks should be passed through stdin
with `-`.

## Model Alias Table

| Alias | Flags | Notes |
|---|---|---|
| `claude/best` | Opus 4.8 in the running Claude Code session | Local invariant: architect/orchestrator judgment stays on Opus 4.8. Do not substitute another Claude model. |
| `codex/best` | `-m gpt-5.5 -c model_reasoning_effort="xhigh"` | Default builder and executor row. |
| `codex/tier-down` | `-m gpt-5.5 -c model_reasoning_effort="high"` | Effort-down only; still GPT-5.5. Use only for routine lanes with recorded reason. |

There is no default Claude builder fallback. If Codex is unavailable, stop and
record the blocker in `.scratch/architect-loop/state/<slice>/verdict.md` or the
active manifest. Tier is fixed at decomposition; a failed job fixes inputs, not
the model tier.

## Storage Contract

All loop artifacts live under `.scratch/architect-loop/` and are expected to be
ignored by Git. The skill does not create issues, branches, commits, PRs, or
committed docs.

Per slice:

```text
.scratch/architect-loop/state/<slice>/
  manifest.json
  spec.md
  gates.md
  freeze/gates.md
  freeze/gates.sha256
  dispatch/<lane>.prompt.md
  reports/<lane>.md
  runs/<lane>.jsonl
  runs/<lane>.stderr.log
  runs/<lane>.last.md
  jobs/<lane>/job.meta.json
  jobs/<lane>/job.heartbeat
  jobs/<lane>/job.exit.json
  checks/<lane>-checkrun.md
  judges/<lane>.md
  patches/<lane>.patch
  final.patch
  verdict.md

.scratch/architect-loop/worktrees/<slice>-<lane>/
.scratch/architect-loop/watchdog/<slice>.json
.scratch/architect-loop/research/<topic>/
```

The authoritative slice state stays in the primary checkout. Each detached
worktree receives a copy of the slice packet under its own `.scratch` and writes
raw report/run artifacts there. The architect ingests those artifacts into the
authoritative state directory after completion.

## Gate Grammar And Check-Runner

Gate files are markdown. Mechanical checks use `RUN:` lines:

```text
- RUN: `git grep -F "needle" -- path/to/file.md` -> exit:0 match:"needle"
```

Contract:

- The first backtick span is the command.
- The expectation starts immediately after the closing backtick as
  `-> exit:<n>`.
- `match:"<fixed substring>"` is optional and case-sensitive. It is not regex.
- Non-`RUN:` text is judge-facing prose.
- A `RUN:` item without an expectation is a check definition error.

Run the deterministic checker after a lane reports complete:

```bash
skills/architect/check-runner.sh .scratch/architect-loop/state/<slice>/checks/<lane>.json
```

Config JSON fields:

```json
{
  "check_file": ".scratch/architect-loop/state/<slice>/gates.md",
  "frozen_check_file": ".scratch/architect-loop/state/<slice>/freeze/gates.md",
  "workdir": "<lane-worktree-or-primary-checkout>",
  "base_sha": "<slice-base-sha>",
  "evidence_out": ".scratch/architect-loop/state/<slice>/checks/<lane>-checkrun.md",
  "executor": "bash",
  "max_output_lines": 60
}
```

Typed exits: `0` means all `RUN:` items passed; `2` means at least one failed;
`5` means check definition or runner error and no partial evidence should be
trusted.

Evidence contains check-file integrity, per-item `expected:` and `verdict:`
lines, and `CHECKRUN SUMMARY: run_items=<n> pass=<n> fail=<n>`.

## Judge Templates

The architect may judge directly for small diffs. For bigger or high-stakes
lanes, send one fresh read-only judge. The template is fixed except paths.

```text
Frozen check file path: <.scratch/architect-loop/state/<slice>/freeze/gates.md>
Live check file path: <.scratch/architect-loop/state/<slice>/gates.md>
Base SHA: <base-sha>
Worktree to judge: <lane worktree or primary checkout>
Spec path: <.scratch/architect-loop/state/<slice>/spec.md>
Lane report: <.scratch/architect-loop/state/<slice>/reports/<lane>.md>
Checkrun evidence: <.scratch/architect-loop/state/<slice>/checks/<lane>-checkrun.md>
Rulings file: <.scratch/architect-loop/state/<slice>/rulings.md> (absent = none)

You are a fresh read-only judge. You did not build this lane. Flag only gaps
that affect correctness, stated requirements, or documented project invariants;
cite file:line evidence. Do not report stylistic preferences.

Batch independent reads in one turn where your harness supports it: frozen
gates, live gates, spec, lane report, rulings, and checkrun evidence. Read the
CHECKRUN SUMMARY before intent review. Do not re-grade every RUN item from the
evidence file. Re-run exactly ONE graded RUN item as a spot-check and compare
verdicts; any mismatch is INVALID with both outputs quoted.

Verdict format:
Checks integrity: PASS | FAIL | INVALID
Diff vs intent: PASS | FAIL | INVALID
Spot-check: PASS | FAIL | INVALID
Lane verdict: PASS | FAIL | INVALID, with one decisive reason.
```

## Scout And Stress-Test Templates

### Scout

Use during intake for non-trivial slices.

```text
You are a read-only code scout. Output path:
.scratch/architect-loop/state/<slice>/scout-map.md

Return <= 2,500 tokens. No recommendations. Include only anchored entries:
key modules/files; load-bearing types/function signatures; conventions;
testing seams; gotchas. Every entry must carry a real file:line anchor. If a
category is absent, write `NOT FOUND: <category> - <searched paths>`. No edits
beyond the output path.
```

### Stress-Test

Run before builder dispatch, after the draft spec and gates exist.

```text
Draft spec path: <.scratch/architect-loop/state/<slice>/spec.md>
Draft gate path: <.scratch/architect-loop/state/<slice>/gates.md>
Source spec/issue paths: <paths>

Task: try to falsify this draft. Execute each draft RUN command against the
current tree when safe, verify every referenced path/SHA/anchor resolves,
attack acceptance criteria for contradictions and non-falsifiability, and flag
assumptions not evidenced in the repo. For every file a lane deletes or renames,
grep the repo for references and verify the owning lane covers them. For every
new artifact path, run `git check-ignore <path>` and flag the plan if it is not
ignored when it should be.

Report format: `<clause>: FALSIFIED | HOLDS` with command output or file:line
evidence; plan findings; assumptions not evidenced.
```

## Canonical Headless Dispatch

Write the builder block to a file first, then pass it via stdin. Always use a
detached scratch worktree, including one-lane slices. Detached worktrees avoid
job branches while keeping builder edits isolated.

```bash
REPO=<repo-root>
SLICE=<slice>
LANE=<NN>
BASE=<base-sha>
STATE="$REPO/.scratch/architect-loop/state/$SLICE"
SKILL_DIR="$REPO/.claude/skills/architect"
[ -d "$SKILL_DIR" ] || SKILL_DIR="$REPO/.agents/skills/architect"
WT="$REPO/.scratch/architect-loop/worktrees/$SLICE-$LANE"
RUN_JSONL="$WT/.scratch/architect-loop/runs/$SLICE-$LANE.jsonl"
LAST_MSG="$WT/.scratch/architect-loop/runs/$SLICE-$LANE.last.md"
REPORT="$WT/.scratch/architect-loop/reports/$SLICE-$LANE.md"
JOB="$STATE/jobs/$LANE"

git -C "$REPO" worktree add --detach "$WT" "$BASE"

mkdir -p "$WT/.scratch/architect-loop/packet/$SLICE"
command cp "$STATE/spec.md" "$WT/.scratch/architect-loop/packet/$SLICE/spec.md"
command cp "$STATE/gates.md" "$WT/.scratch/architect-loop/packet/$SLICE/gates.md"
command cp "$STATE/freeze/gates.md" "$WT/.scratch/architect-loop/packet/$SLICE/frozen-gates.md"
command cp "$STATE/manifest.json" "$WT/.scratch/architect-loop/packet/$SLICE/manifest.json"

mkdir -p "$WT/.scratch/architect-loop/reports" "$WT/.scratch/architect-loop/runs" "$JOB"

"$SKILL_DIR/run-job.sh" \
  --job-dir "$JOB" \
  --workdir "$WT" \
  --backend codex-cli \
  --report-path "$REPORT" \
  --events-file "$RUN_JSONL" \
  --stdin-file "$STATE/dispatch/$LANE.prompt.md" \
  --sandbox-env \
  -- \
  codex exec -C "$WT" --sandbox workspace-write \
  -m gpt-5.5 -c model_reasoning_effort="xhigh" \
  --json -o "$LAST_MSG" \
  -
```

`--json` is the event stream and must be captured from stdout. `-o` is only the
last assistant message; do not name it `.jsonl`. The wrapper writes
`job.meta.json`, `job.heartbeat`, `stderr.log`, and `job.exit.json` under
`$STATE/jobs/$LANE`; use that wrapper exit truth when judging a lane and when
configuring the watchdog.

## Post-Flight Checks

Per lane, from the primary checkout:

```bash
REPO=<repo-root>
SLICE=<slice>
LANE=<NN>
BASE=<base-sha>
STATE="$REPO/.scratch/architect-loop/state/$SLICE"
WT="$REPO/.scratch/architect-loop/worktrees/$SLICE-$LANE"

mkdir -p "$STATE/reports" "$STATE/runs" "$STATE/checks" "$STATE/patches"
command cp "$WT/.scratch/architect-loop/reports/$SLICE-$LANE.md" "$STATE/reports/$LANE.md"
command cp "$WT/.scratch/architect-loop/runs/$SLICE-$LANE.jsonl" "$STATE/runs/$LANE.jsonl"
command cp "$STATE/jobs/$LANE/stderr.log" "$STATE/runs/$LANE.stderr.log"
command cp "$WT/.scratch/architect-loop/runs/$SLICE-$LANE.last.md" "$STATE/runs/$LANE.last.md"
test -s "$STATE/runs/$LANE.jsonl"
test -s "$STATE/jobs/$LANE/job.exit.json"
python3 -c 'import json,sys; lines=[l for l in open(sys.argv[1]) if l.strip()]; [json.loads(l) for l in lines]; assert lines' "$STATE/runs/$LANE.jsonl"

(cd "$STATE/freeze" && shasum -a 256 -c gates.sha256)
diff -u "$STATE/freeze/gates.md" "$STATE/gates.md"

git -C "$WT" status --porcelain --untracked-files=all
git -C "$WT" diff --name-only "$BASE"
git -C "$WT" ls-files --others --exclude-standard
git -C "$WT" diff "$BASE" -- <allowed-files...>
```

Fail the lane if any changed or untracked implementation file is outside the
declared allowlist. Ignored `.scratch` files are artifacts, not implementation
files.

## Patch Bundle Finalization

Finalization produces local patch files only.

```bash
REPO=<repo-root>
SLICE=<slice>
LANE=<NN>
BASE=<base-sha>
STATE="$REPO/.scratch/architect-loop/state/$SLICE"
WT="$REPO/.scratch/architect-loop/worktrees/$SLICE-$LANE"

# only if the lane created new allowed files:
git -C "$WT" add -N -- <new-allowed-files...>
git -C "$WT" diff --binary "$BASE" -- <allowed-files...> > "$STATE/patches/$LANE.patch"
git -C "$REPO" apply --check "$STATE/patches/$LANE.patch"
```

For accepted lanes, concatenate patches in dependency order:

```bash
: > "$STATE/final.patch"
for p in "$STATE"/patches/*.patch; do
  [ -s "$p" ] && cat "$p" >> "$STATE/final.patch"
done
git -C "$REPO" apply --check "$STATE/final.patch"
```

Do not apply, stage, branch, commit, push, or open a PR by default. The human
reviews `final.patch` and decides what to do next.

## Watchdog Dispatch

Use the script watchdog for unattended waves. It is detection-only.

```json
{
  "sweep_sec": 120,
  "stall_after_min": 10,
  "heartbeat_stale_sec": 240,
  "report_ready_grace_sec": 120,
  "jobs": [
    {
      "id": "<slice-lane>",
      "events_file": "<worktree>/.scratch/architect-loop/runs/<slice-lane>.jsonl",
      "report_path": "<worktree>/.scratch/architect-loop/reports/<slice-lane>.md",
      "job_dir": ".scratch/architect-loop/state/<slice>/jobs/<lane>",
      "exit_file": ".scratch/architect-loop/state/<slice>/jobs/<lane>/job.exit.json",
      "heartbeat_file": ".scratch/architect-loop/state/<slice>/jobs/<lane>/job.heartbeat",
      "stderr_file": ".scratch/architect-loop/state/<slice>/jobs/<lane>/stderr.log",
      "worktree": "<worktree>",
      "duration_hint_min": 0
    }
  ]
}
```

Run:

```bash
skills/architect/watchdog.sh .scratch/architect-loop/watchdog/<slice>.json
```

Typed exits: `0 WATCHDOG: ALL_DONE`, `2 WATCHDOG: INTEGRATED`, `3 WATCHDOG:
STALL`, `4 WATCHDOG: REPEAT`, `6 WATCHDOG: REPORT_READY`, `9 WATCHDOG:
DONE_FAILED`.

The watchdog never kills, nudges, judges, edits files, or changes Git state.

## Stall Detection And Rescue

A dispatched run is STALLED when its JSONL output, stderr, and report stop
growing, the process tree shows no activity beyond the duration hint, or the
last parsed commands repeat mechanically. Silent gaps are normal model thinking.

Diagnose before killing. If a child process is stuck, kill the narrowest child,
not the whole Codex run. Kill the whole lane only after the same hang repeats or
the worktree is broken; then discard the worktree and respawn from updated
inputs.

Known sandbox hang sources: `asyncio.create_subprocess_exec`, Playwright
browser launch, anyio subprocess pools, out-of-workspace temp paths, and
cache/temp directories outside the workspace. Route such commands to
in-workspace temp/cache paths or record BLOCKED.

## Builder Block Template

```text
Execute the architect spec below. Operating rules:

REQUIRED LOCAL SKILLS - Before PHASE 0:
Read every skill file listed in the REQUIRED LOCAL SKILLS section. If one is
missing or unreadable, state that in PHASE 0 and mark the lane
COMPLETE_WITH_CONCERNS or BLOCKED depending on risk.

PHASE 0 - Before code:
Reply with your plan and EVERY disagreement you have with this spec, with
reasons citing real files. Silent compliance is a failure. If there are no
disagreements, state what you checked before concluding the spec is sound.

PHASE 1 - Frozen packet:
The packet and frozen gates under `.scratch/architect-loop/packet/<slice>/`
are read-only. Editing packet artifacts or regenerating criteria fails the
lane.

PHASE 2 - Build YOUR LANE ONLY:
Implementation changes may touch only the files listed in BOUNDARIES. Write the
lane report under `.scratch/architect-loop/reports/`. Keep all `.scratch`
artifacts ignored and untracked. No placeholder implementations. Search before
implementing. Full implementations only.

Verification:
Run the lane's gate commands sequentially and record raw output plus a gate
ledger: frozen command, actual command, cwd/env, exit status, output path,
post-run source diff, and PASS / FAIL / BLOCKED / DEVIATED. Do NOT commit. Do
NOT delete or update lock files outside the declared boundary. Give long
commands explicit timeouts. If a runtime cannot start under the sandbox, record
the exact failure and stop.

When done, write your lane report to:
.scratch/architect-loop/reports/<slice>-<lane>.md

Use RAW results only: command output, file paths, SHAs, tables, numbers. Every
status claim must be backed by a command result from this run. Include `Skills
used:` and `Extra context loaded:` lines. End with exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker
and what you tried).

Verdicts belong to the architect and human. Persist until your lane is handled
end to end; do not stop at analysis or partial fixes.

=== OBJECTIVE (and why) ===
...

=== OUTPUT FORMAT ===
...

=== TOOL GUIDANCE ===
...

=== REQUIRED LOCAL SKILLS ===
...

=== BOUNDARIES ===
...

=== DISAGREEMENT RULINGS ===
...

=== ACCEPTANCE GATES ===
...
```
