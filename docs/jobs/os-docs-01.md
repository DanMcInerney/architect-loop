# os-docs-01 report

## PHASE 0

MIRROR: ORCHESTRATOR

Input verification:

```text
Test-Path docs/checks/os-docs.md
True
Test-Path skills/architect/postflight.ps1
True
Test-Path docs/spec/orchestrator-scripts.md
True
Select-String -Path docs/spec/orchestrator-scripts.md -Pattern '^### D5\. check-runner quoting fix \(amendment\)$'
docs\spec\orchestrator-scripts.md:112:### D5. check-runner quoting fix (amendment)
```

Plan:

- Edit `README.md` only inside the existing factory-flow description.
- Edit `DESIGN.md` under `### Judging and integration`.
- Add `docs/solutions/orchestrator-mechanics-offload.md`.
- Do not edit `skills/**`, `tests/**`, `docs/checks/**`, or `docs/spec/**`.
- Run `docs/checks/os-docs.md` commands with PowerShell, native `git.exe`, and `UV_CACHE_DIR=.architect/tmp/uv-cache-os`.
- Report raw evidence only. Do not commit.

Disagreements:

- None with issue #72 or the frozen contract.

Frozen input evidence:

```text
docs/checks/os-docs.md:3:Purpose: verify product docs and solutions debt for the orchestrator-scripts ship.
docs/checks/os-docs.md:5:Spec (fix contract): `docs/spec/orchestrator-scripts.md`.
docs/checks/os-docs.md:6:Files owned: `README.md`, `DESIGN.md`, `docs/solutions/**`.
docs/checks/os-docs.md:13:- RUN: `git grep -c "postflight" -- README.md` -> >= 1
docs/checks/os-docs.md:17:- RUN: `git grep -c "postflight" -- DESIGN.md` -> >= 2
docs/checks/os-docs.md:18:- RUN: `git grep -c "typed-exit" -- DESIGN.md` -> >= 1
docs/checks/os-docs.md:22:- RUN: `Test-Path docs/solutions/orchestrator-mechanics-offload.md` -> True
docs/checks/os-docs.md:23:- RUN: `git grep -c "2026-07-04" -- docs/solutions/orchestrator-mechanics-offload.md` -> >= 1
docs/checks/os-docs.md:27:- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python tests/validate_skills.py` -> output contains `OK`
```

```text
docs\spec\orchestrator-scripts.md:52:Design-it-twice (interface): (A) positional CLI args — rejected: 6+ params,
docs\spec\orchestrator-scripts.md:53:quoting hazards on Windows, inconsistent with watchdog/check-runner; (B)
docs\spec\orchestrator-scripts.md:55:siblings, diffable, written with file tools; (C) env vars — rejected:
docs\spec\orchestrator-scripts.md:56:invisible state, PS 5.1/bash divergence.
docs\spec\orchestrator-scripts.md:112:### D5. check-runner quoting fix (amendment)
docs\spec\orchestrator-scripts.md:114:The runner must deliver each RUN command to its executor byte-identical to
```

Edited files:

```text
README.md
DESIGN.md
docs/solutions/orchestrator-mechanics-offload.md
docs/jobs/os-docs-01.md
```

Check evidence:

```text
git.exe grep -c "postflight" -- README.md; $LASTEXITCODE
README.md:1
0
```

```text
git.exe grep -c "postflight" -- DESIGN.md; $LASTEXITCODE
DESIGN.md:2
0
```

```text
git.exe grep -c "typed-exit" -- DESIGN.md; $LASTEXITCODE
DESIGN.md:1
0
```

```text
Test-Path docs/solutions/orchestrator-mechanics-offload.md
True
```

```text
git.exe add -N -- docs/solutions/orchestrator-mechanics-offload.md; $LASTEXITCODE
128
fatal: Unable to create 'C:/Users/danhm/tools/architect-loop/.git/worktrees/os-docs-01/index.lock': Permission denied
```

```text
New-Item -ItemType Directory -Force -Path .architect/tmp | Out-Null
$env:GIT_INDEX_FILE = Join-Path (Resolve-Path .architect/tmp) ("os-docs-index-objects-$PID")
$env:GIT_OBJECT_DIRECTORY = (Resolve-Path .architect/tmp/git-objects).Path
$common = git.exe rev-parse --git-common-dir
$env:GIT_ALTERNATE_OBJECT_DIRECTORIES = (Resolve-Path (Join-Path $common 'objects')).Path
git.exe read-tree HEAD
git.exe add -- README.md DESIGN.md docs/solutions/orchestrator-mechanics-offload.md
git.exe grep -c "2026-07-04" -- docs/solutions/orchestrator-mechanics-offload.md
docs/solutions/orchestrator-mechanics-offload.md:1
LASTEXITCODE=0
warning: in the working copy of 'DESIGN.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'README.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'docs/solutions/orchestrator-mechanics-offload.md', LF will be replaced by CRLF the next time Git touches it
```

```text
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'
uv run --no-project python tests/validate_skills.py
OK - 2 skills validated, v4 contracts clean
LASTEXITCODE=0
```

Judge-only evidence:

```text
DESIGN.md:338:Run #62 measured the motivation: every dispatch cost about 4-5 orchestrator
DESIGN.md:339:calls (claim, worktree add, HEAD-vs-freeze verify, frozen-file spot-check, and
DESIGN.md:340:block assembly), every merge cost another 4+ calls (merge, push, worktree
DESIGN.md:341:remove, and branch delete), and the touch-set audit was still informal. These
```

```text
DESIGN.md:345:The pattern is now a typed-exit script family: watchdog → check-runner →
DESIGN.md:346:preflight/postflight. The watchdog reports liveness facts, the check-runner
DESIGN.md:347:records frozen RUN evidence, dispatch preflight creates and verifies the
DESIGN.md:348:worktree and frozen inputs, and merge postflight performs the touch-set audit,
DESIGN.md:349:merge, optional push, and cleanup. Each script emits typed evidence; the
```

```text
DESIGN.md:352:The interface design-it-twice record rejected positional arguments and env vars
DESIGN.md:353:in favor of one config JSON path: positional args had six-plus parameters,
DESIGN.md:354:Windows quoting hazards, and no sibling consistency, while env vars hid state
DESIGN.md:355:and diverged between PowerShell 5.1 and bash. The full record lives in the
DESIGN.md:356:[orchestrator-scripts design section](docs/spec/orchestrator-scripts.md#design).
```

```text
DESIGN.md:358:Run #68 was the first live use of the runner-fed judge path shipped in #62/PR
DESIGN.md:359:#67. Its first execution produced a D3-conformant evidence file but
DESIGN.md:360:quote-mangled every RUN command with quoted multi-word arguments because child
DESIGN.md:361:PowerShell `-Command` stripped quotes; the preserved defect evidence is
DESIGN.md:362:[docs/jobs/os-wiring-checkrun.md](docs/jobs/os-wiring-checkrun.md). The defect
DESIGN.md:363:was fixed in-run by the human-approved D5 amendment (#73), then validated
DESIGN.md:364:through the same path it repairs: the fixed runner executed its own frozen
DESIGN.md:365:acceptance checks and three subsequent evidence-consuming judgments (#73, #69,
DESIGN.md:366:#71), all grading committed evidence with spot-check re-runs. The judge
DESIGN.md:367:tree-audit guard also caught an orchestrator orphan-race snapshot commit
DESIGN.md:368:(judgment #2 on #71, INVALID), which shows the honesty guards catch defects in
DESIGN.md:369:both directions.
```

```text
README.md:130:   - **Dispatch and merge mechanics are scripted.** Dispatch preflight creates
README.md:131:     and verifies the worktree and frozen inputs; merge postflight runs the
README.md:132:     touch-set audit, merge, optional push, and cleanup. Both are deterministic
README.md:133:     typed-exit scripts, so the orchestrator reasons over one factual line
README.md:134:     instead of replaying the mechanics by hand.
```

Solution evidence:

```text
docs\solutions\orchestrator-mechanics-offload.md:2:Recorded: 2026-07-04
docs\solutions\orchestrator-mechanics-offload.md:7:mechanics. Run #62 measured about 4-5 orchestrator calls per dispatch and 4+
docs\solutions\orchestrator-mechanics-offload.md:28:- Fixtures without load-bearing quoted multi-word arguments missed the
docs\solutions\orchestrator-mechanics-offload.md:33:- A builder silently weakened the validator guard from 800 to 900 lines,
docs\solutions\orchestrator-mechanics-offload.md:36:  `docs/jobs/os-validator-rulings.md` R2, with a justification comment.
```

```text
docs\jobs\os-validator-rulings.md:18:Judge F2 UPHELD: silent 800->900 guard weakening = silent-fallback ban
docs\jobs\os-validator-rulings.md:19:violation; correct move was BLOCKED-with-evidence.
docs\jobs\os-validator-rulings.md:20:HUMAN RULING (assumption-collision hard stop): 900 authorized, recorded.
```

```text
docs\jobs\os-wiring-checkrun.md:16:fatal: no pattern given
docs\jobs\os-wiring-checkrun.md:21:fatal: unable to resolve revision: OK
docs\jobs\os-wiring-checkrun.md:26:fatal: unable to resolve revision: VIOLATION
docs\jobs\os-wiring-checkrun.md:29:$ git grep -c "POSTFLIGHT: CONFLICT" -- skills/architect/dispatch.md
docs\jobs\os-wiring-checkrun.md:31:fatal: unable to resolve revision: CONFLICT
```

Scope evidence:

```text
git.exe status --short -- skills tests docs/checks docs/spec
```

```text
git.exe status --short -- README.md DESIGN.md docs/solutions docs/jobs/os-docs-01.md
 M DESIGN.md
 M README.md
?? docs/solutions/orchestrator-mechanics-offload.md
?? docs/jobs/os-docs-01.md
```

STATUS: COMPLETE
