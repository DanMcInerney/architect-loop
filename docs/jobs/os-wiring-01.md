PHASE 0

Plan:
- `docs/spec/orchestrator-scripts.md:89` requires `dispatch.md` to add `## Preflight and postflight dispatch`, verbatim config contracts, typed exits, exit 3 as decomposition failure, exit 2 as automatic FAIL evidence, and the Codex-backend scoping note.
- `docs/spec/orchestrator-scripts.md:95` requires `loop.md` to name postflight and its typed exits in the merge step.
- `docs/spec/orchestrator-scripts.md:96` requires `SKILL.md` step 3 and step 4 to name the scripts with minimal edits.
- `docs/checks/os-wiring.md:5` owns only `skills/architect/SKILL.md`, `skills/architect/loop.md`, and `skills/architect/dispatch.md`; `docs/checks/os-wiring.md:8` names powershell plus native `git.exe` and exempts `docs/jobs/`.

Disagreements:
- None. Checked binding spec D3, Interface contract, frozen checks WI1-WI5, and existing anchors `## Integration commands`, `## Factory block procedure`, and `## Hard Rules`.

Input verification:
```text
COMMAND: git rev-parse HEAD
OUTPUT:
4ebe337a65e0fe616eb4d3310a307c8eba3c8179

COMMAND: Test-Path -LiteralPath 'docs/checks/os-wiring.md'
OUTPUT:
True
```

Edited line evidence:
```text
skills/architect/dispatch.md:260: Default dispatch and integration are script-backed. The orchestrator writes one
skills/architect/dispatch.md:261: config JSON, runs the platform script, and rules on the typed line.
skills/architect/dispatch.md:263: Preflight worktree creation is the Codex-backend path only. Claude-backend jobs
skills/architect/dispatch.md:264: never pre-create worktrees; use the harness-created worktree and branch from
skills/architect/dispatch.md:265: the Per-harness delegation table instead.

skills/architect/dispatch.md:314: Integration is architect-only, after per-job postflight passes. The default
skills/architect/dispatch.md:315: path is `postflight.ps1` or `postflight.sh` from `## Preflight and postflight
skills/architect/dispatch.md:316: dispatch`; it performs the touch-set audit, merge, optional push, and cleanup
skills/architect/dispatch.md:317: from the config. The manual sequence below is the recorded fallback for exit 5
skills/architect/dispatch.md:318: or an environment where the script cannot run. The `.architect/wt/<slice>-<NN>`
skills/architect/dispatch.md:324: Recorded fallback manual sequence:

skills/architect/SKILL.md:150: - Dispatch has hard-stop preconditions, in order: freeze committed on the
skills/architect/SKILL.md:151:   factory branch; factory branch pushed; `preflight.ps1`/`preflight.sh`
skills/architect/SKILL.md:152:   executes worktree creation, freeze-verify, and frozen-file spot-check.
skills/architect/SKILL.md:200: - On DONE, write the runner config, launch the check-runner in the background, let its exit wake the loop, commit the checkrun evidence file, then send a fresh, independent orchestrator-tier judge with the evidence path.
skills/architect/SKILL.md:201:   Merge through postflight only after a passing verdict; `POSTFLIGHT: OK` exit
skills/architect/SKILL.md:202:   0 is the clean touch-set evidence.

skills/architect/loop.md:18:    - **Job DONE.** Ordering: write the runner config; launch `check-runner.ps1`
skills/architect/loop.md:19:      or `check-runner.sh` as a background process whose exit is the next wake; commit the checkrun artifact `docs/jobs/<issue-slug>-checkrun.md`; then send the fixed judge template from `dispatch.md` to one fresh judge subagent with the evidence path. Record the verdict in an issue comment (see Verdict comments). On PASS, run `postflight.ps1` or `postflight.sh`: exit 0 `POSTFLIGHT: OK` means merge completed with clean touch-set evidence; exit 2 `POSTFLIGHT: VIOLATION` is automatic FAIL evidence for the job; exit 3 `POSTFLIGHT: CONFLICT` is the merge-conflict decomposition-failure rail; exit 5 `POSTFLIGHT: ERROR` falls back to the recorded manual integration sequence in `dispatch.md`. On FAIL, diagnose (see Failure ladder).
skills/architect/loop.md:80: the digest. A merge conflict, including postflight exit 3, is a decomposition
skills/architect/loop.md:81: failure, not a build failure: kill the conflicting job and re-spec; never
skills/architect/loop.md:102: | Merge conflict or postflight exit 3 | Decomposition failure: kill the job, re-spec. |
```

WI1-WI4 RUN evidence:
```text
COMMAND: git grep -c "## Preflight and postflight dispatch" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "PREFLIGHT: OK" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "POSTFLIGHT: VIOLATION" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "POSTFLIGHT: CONFLICT" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "require_files" -- skills/architect/dispatch.md
skills/architect/dispatch.md:2
EXIT: 0

COMMAND: git grep -c "merge_message" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "factory_branch" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "exit 3" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "decomposition failure" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "POSTFLIGHT: ERROR" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "postflight" -- skills/architect/loop.md
skills/architect/loop.md:3
EXIT: 0

COMMAND: git grep -c "preflight.ps1" -- skills/architect/SKILL.md
skills/architect/SKILL.md:1
EXIT: 0

COMMAND: git grep -c "postflight" -- skills/architect/SKILL.md
skills/architect/SKILL.md:1
EXIT: 0

COMMAND: (Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() }).Count
209

COMMAND: (Get-Content skills/architect/loop.md | Where-Object { $_.Trim() }).Count
100

COMMAND: (Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() }).Count
540
```

Scope and whitespace evidence:
```text
COMMAND: git diff --name-only
OUTPUT:
skills/architect/SKILL.md
skills/architect/dispatch.md
skills/architect/loop.md

COMMAND: git diff -- docs/checks
OUTPUT:

COMMAND: git diff --check
OUTPUT:
warning: in the working copy of 'skills/architect/SKILL.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/loop.md', LF will be replaced by CRLF the next time Git touches it
```

Tracker mirror:
```text
MIRROR: ORCHESTRATOR
```

STATUS: COMPLETE
