# Job report: ground-scripts/s1-ground

Issue: #130 (`ground-scripts s1-ground`, tracking #129).
Spec: `docs/spec/ground-scripts.md`. Check: `docs/checks/ground-scripts/s1-ground.md`.
Builds: `skills/architect/ground.ps1`, `skills/architect/ground.sh`.

## PHASE 0 (posted verbatim to issue #130 before build)

Plan: read `docs/spec/ground-scripts.md` + `docs/checks/ground-scripts/s1-ground.md`
(read-only), study `skills/architect/status.ps1`/`status.sh` for arg-parsing,
frontmatter-parse (`fm`), and `gh --jq` conventions, then build
`ground.ps1`/`ground.sh` implementing: manifest parse, tracker reconcile
(github via `gh` scoped by the `<!-- architect-run: <run> -->` marker;
markdown via `docs/issues/<run>/`), freeze verification (tracking-issue body
or latest `docs/checks/<run>/` commit, diffed against HEAD), branch check vs
origin, ungraded-report detection, STOP/env gates, and frontier computation —
all detection-only, plain ASCII, no writes.

Disagreements / gaps found in the frozen check and spec, with evidence:

1. **The spec never defines the freeze-SHA-on-tracking-issue-body format.**
   `docs/spec/ground-scripts.md` line 20 says "verify the recorded freeze
   SHA" and `SKILL.md` line 137 says only "Record freeze SHA... on the
   tracking issue" with no field/line convention (unlike the manifest's
   fixed `key: value` frontmatter, tracker.md `## Markdown issue format`).
   Checked: issue #129's actual body (`gh issue view 129 --json body`) has no
   freeze SHA at all — the checks were frozen but the SHA was never posted to
   the tracking issue. I resolved this by (a) implementing a permissive
   `freeze[^0-9a-fA-F]*([0-9a-f]{7,40})` regex over the body text so any
   future `freeze: <sha>`-shaped text is picked up, and (b) always falling
   back to `git log -1 -- docs/checks/<run>/` when no match is found — which
   is exactly what happened on this live run (freeze resolved to `44d3ce9`,
   matching the actual freeze commit and `factory/ground-scripts`'s synced
   origin head). This is a spec gap, not a blocker: the fallback makes the
   feature work today, but a future spec/build should fix the recording
   format so the body-parse path is exercised for real.
2. **"tracker/git disagreement" (one of the two named DRIFT triggers) has no
   concrete definition anywhere in the spec, checks, or SKILL.md/loop.md.**
   Checked `docs/spec/ground-scripts.md`, `s1-ground.md`, `SKILL.md`
   Ground section, `loop.md` Hard Stops table — none define what
   "disagreement" means mechanically. I implemented a concrete, minimal
   version: manifest `state: ACTIVE` while the tracking issue is tracker-side
   `CLOSED` (or `state: FINISHED` while still tracker-side `OPEN`) is DRIFT.
   This is a real, testable git-vs-tracker inconsistency; I did not invent a
   more elaborate signal (e.g. per-issue git-log cross-referencing) given
   "no judgment in scripts" (spec Non-goals) and detection-only scope. Flagging
   this as a spec gap for the orchestrator/human to confirm or extend, not a
   blocker — DRIFT (exit 3) is reachable and I exercised it directly (see
   Evidence below).
3. **No disagreement with the `<run> [-RepoRoot|--repo-root <path>]` shape**:
   confirmed by reading `status.ps1`/`status.sh` that the convention is
   `-RepoRoot` on the PS1 side and `--repo-root`/`--repo-root=` on the sh
   side (not both spellings on both scripts) — `ground.ps1`/`ground.sh` match
   that precedent exactly.

No other disagreements. Proceeded to build per the plan above.

## Evidence — frozen check RUN items (from worktree root, this session)

```
$ test -f skills/architect/ground.ps1 -a -f skills/architect/ground.sh
exit=0

$ bash skills/architect/ground.sh ground-scripts
ISSUE: 129 open blockedBy=none
ISSUE: 130 open blockedBy=none
ISSUE: 131 closed blockedBy=none
ISSUE: 132 open blockedBy=131,130
BRANCH: factory/ground-scripts 074ccd78d55c815634872601d9ffdcc3f3c94797 synced
FRONTIER: 130
GROUND: OK issues=1/3 frontier=1 freeze=44d3ce9
exit=0

$ bash -c 'bash skills/architect/ground.sh ground-scripts | grep -c "FRONTIER:"'
1
exit=0

$ bash -c 'CLAUDE_CODE_SUBAGENT_MODEL=haiku bash skills/architect/ground.sh ground-scripts; test $? -eq 2 && echo STOP_GATE_OK'
GROUND: STOP subagent-model-env
STOP_GATE_OK
exit=0

$ bash -c 'bash skills/architect/ground.sh no-such-run 2>&1; test $? -eq 5 && echo ERROR_RAIL_OK'
GROUND: ERROR missing manifest: /c/Users/danhm/tools/architect-loop/.claude/worktrees/agent-a5d0e1ae294983e7d/docs/runs/no-such-run/manifest.md
ERROR_RAIL_OK
exit=0

$ bash -c 'powershell -NoProfile -ExecutionPolicy Bypass -File skills/architect/ground.ps1 ground-scripts | grep -q "GROUND: OK" && echo PS_OK'
PS_OK
exit=0

$ bash -c 'out=$(bash skills/architect/ground.sh ground-scripts); git status --porcelain | grep -v "^??" | wc -l | grep -qx 0 && echo READONLY_OK'
READONLY_OK
exit=0
```

All 7 RUN items: exit 0, matched text present. Note: issue #131 (`s2-ffcheck`)
transitioned OPEN -> CLOSED between runs (a sibling job merged during this
session) — the reconcile output changed live between the exploratory run and
the final run above, confirming `ground.sh`/`.ps1` read real tracker state
rather than a cached/stale view. `.ps1` output is byte-identical to `.sh`
output on both the live run and every fixture below (diffed by eye; both
scripts were run back-to-back against the same repo state each time).

## Evidence — my own tests at the seam (tdd skill; frozen check is not my test suite)

Frozen-check RUN items only exercise the OK/STOP(env)/ERROR/read-only paths on
the live github-tracker run. I built a throwaway markdown-tracker fixture
repo under `.architect/tmp`-equivalent scratch space (outside this repo, per
job boundaries — `git init` in the scratchpad, never touching this
worktree) to exercise every other named behavior at the same CLI seam:
markdown tracker mode, frontier blocking-edge computation, freeze DRIFT,
ungraded-report DRIFT, both STOP-file gates (including the
`--git-common-dir`-derived primary-checkout path from a *second* worktree),
and PS1/SH parity on all of the above. Fixture: tracking issue #1 (OPEN,
no freeze in body), child #2 OPEN unblocked, child #3 CLOSED, child #4 OPEN
blocked-by `2,3`.

```
# markdown-mode OK + frontier (only #2 is open+unblocked; #4 blocked by open #2)
$ bash ground.sh fixrun --repo-root <fixture>
ISSUE: 1 open blockedBy=none
ISSUE: 2 open blockedBy=none
ISSUE: 3 closed blockedBy=none
ISSUE: 4 open blockedBy=2,3
BRANCH: factory/fixrun missing
FRONTIER: 2
GROUND: OK issues=1/3 frontier=1 freeze=05e046f
exit=0
# ground.ps1 on the same fixture: byte-identical output, exit=0

# freeze DRIFT: pinned freeze SHA recorded in tracking-issue body text, then a
# further commit edits docs/checks/fixrun/ after that recorded point
$ bash ground.sh fixrun --repo-root <fixture>
...
GROUND: DRIFT docs/checks/fixrun/ changed since freeze 05e046f4e7e44142ca80f5d4ca2c007ed38ec223
exit=3
# ground.ps1 on the same fixture state (later re-pin + second edit): same DRIFT shape, exit=3

# ungraded DRIFT: docs/jobs/fixrun/slice-a-01.md written with no matching
# -checkrun.md
$ bash ground.sh fixrun --repo-root <fixture>
...
UNGRADED: slice-a-01
GROUND: DRIFT ungraded job report(s) present without checkrun evidence
exit=3
# adding slice-a-01-checkrun.md restores GROUND: OK (verified, exit=0)

# STOP gates
$ touch docs/runs/fixrun/STOP && bash ground.sh fixrun --repo-root <fixture>
GROUND: STOP run-stop
exit=2
$ touch docs/STOP && bash ground.sh fixrun --repo-root <fixture>
GROUND: STOP run-checkout
exit=2
# primary-checkout gate, invoked from a second `git worktree add` pointed at
# the fixture (docs/STOP placed only in the primary checkout):
$ bash ground.sh fixrun --repo-root <secondary-worktree>
GROUND: STOP primary-checkout
exit=2
$ powershell ... ground.ps1 fixrun -RepoRoot <secondary-worktree>
GROUND: STOP primary-checkout
exit=2

# ERROR rail, bad args
$ powershell ... ground.ps1 no-such-run -RepoRoot <fixture>
GROUND: ERROR missing manifest: <fixture>\docs/runs\no-such-run\manifest.md
exit=5
```

One real defect found and fixed during this testing (not present in the
frozen-check-only path, since the live run's `factory/ground-scripts` branch
has an `origin` remote): `ground.ps1`'s original `git ls-remote origin ...`
call, run against the fixture repo (no `origin` remote configured), crashed
the whole script with an uncaught `NativeCommandError` under
`$ErrorActionPreference = "Stop"` — this matches the documented PowerShell
5.1 gotcha (a non-zero-exit native command with redirected stderr is promoted
to a terminating error even with `2>$null`, not just `2>&1`). Fixed by adding
a `GitTry` helper that wraps every fallible `git` call
(`ls-remote`, `rev-parse --verify`, `cat-file -e`, `rev-list`, `log -1`,
`diff --stat`) in try/catch and treats a thrown/non-zero result as "not
found" rather than crashing. Re-verified against both the fixture (no
origin) and the live repo (has origin, `BRANCH: ... synced`) after the fix —
both pass, `.sh` and `.ps1` outputs match.

## Boundary compliance

Touched only `skills/architect/ground.ps1`, `skills/architect/ground.sh`, and
this report. `docs/checks/` was read, never written. No commits made. No
tracker posts made except the required PHASE 0 comment and this report's
mirrored STATUS comment on issue #130 (per job instructions). All fixture
work happened in a separate scratch git repo outside this worktree; final
`git status --porcelain` in this worktree shows only the two new script
files.

## Fix round 1 (2026-07-06, per s1-ground ruling — checkrun exit 2)

Ruling read from `git show 6844877:docs/jobs/ground-scripts/s1-ground-rulings.md`
(the rulings file is orchestrator-owned; not created or edited in this
worktree). Two facts ruled:

1. REAL DEFECT: my ungraded-report matcher paired `<slug>-01.md` with
   `<slug>-01-checkrun.md`; the repo convention is `<issue-slug>-checkrun.md`
   (dispatch.md line 129; confirmed by `git ls-tree 6844877
   docs/jobs/ground-scripts/`: `s2-ffcheck-01.md` + `s2-ffcheck-checkrun.md`).
2. CHECK-CONTEXT: frozen items 2/3/6 cannot see `GROUND: OK` from this
   worktree because my own report sits ungraded here at grading time — the
   exit-3 DRIFT is correct detection. Ruled substitute: a recorded
   clean-state demonstration, both executors.

### Fix

Both scripts now glob `*-NN.md` reports, strip the trailing `-NN`
(`sed 's/-[0-9][0-9]$//'` in `.sh`; `-replace '-[0-9][0-9]$', ''` in `.ps1`),
and pair against `<issue-slug>-checkrun.md`; `UNGRADED:` emits the issue slug.

### Red (defect reproduced before the fix, markdown fixture)

Fixture checkrun renamed to convention `slice-a-checkrun.md`; pre-fix matcher:

```
UNGRADED: slice-a-01
GROUND: DRIFT ungraded job report(s) present without checkrun evidence
exit=3        <- false positive: slice-a-checkrun.md exists
```

### Green (after the fix; byte-identical .sh/.ps1 on every state below)

```
# fixture, convention checkrun present -> OK, both executors
FRONTIER: 2
GROUND: OK issues=1/3 frontier=1 freeze=44b1753
exit=0
# negative: truly ungraded slice-b-01.md (no slice-b-checkrun.md) still drifts
UNGRADED: slice-b
GROUND: DRIFT ungraded job report(s) present without checkrun evidence
exit=3
```

### Clean-state demonstration (ruled substitute for frozen items 2/3/6)

Detached temp worktree at factory head 6844877 (`.architect/tmp/ground-clean`,
removed after) — real github tracker mode, every report paired
(`s2-ffcheck-01.md` + `s2-ffcheck-checkrun.md`, the ruling's exact falsifying
case), checks unchanged since freeze:

```
$ bash skills/architect/ground.sh ground-scripts --repo-root <repo>/.architect/tmp/ground-clean
ISSUE: 129 open blockedBy=none
ISSUE: 130 open blockedBy=none
ISSUE: 131 closed blockedBy=none
ISSUE: 132 open blockedBy=131,130
BRANCH: factory/ground-scripts 6844877f3fe41702e4603e8f2bf88fa31e0b5c19 synced
FRONTIER: 130
GROUND: OK issues=1/3 frontier=1 freeze=44d3ce9
exit=0

$ powershell -NoProfile -ExecutionPolicy Bypass -File skills/architect/ground.ps1 ground-scripts -RepoRoot <repo>/.architect/tmp/ground-clean
ISSUE: 129 open blockedBy=none
ISSUE: 130 open blockedBy=none
ISSUE: 131 closed blockedBy=none
ISSUE: 132 open blockedBy=131,130
BRANCH: factory/ground-scripts 6844877f3fe41702e4603e8f2bf88fa31e0b5c19 synced
FRONTIER: 130
GROUND: OK issues=1/3 frontier=1 freeze=44d3ce9
exit=0
```

### Frozen items 1/4/5/7 re-run verbatim (worktree root, post-fix)

```
$ test -f skills/architect/ground.ps1 -a -f skills/architect/ground.sh
exit=0

$ bash -c 'CLAUDE_CODE_SUBAGENT_MODEL=haiku bash skills/architect/ground.sh ground-scripts; test $? -eq 2 && echo STOP_GATE_OK'
GROUND: STOP subagent-model-env
STOP_GATE_OK
exit=0

$ bash -c 'bash skills/architect/ground.sh no-such-run 2>&1; test $? -eq 5 && echo ERROR_RAIL_OK'
GROUND: ERROR missing manifest: /c/Users/danhm/tools/architect-loop/.claude/worktrees/agent-a5d0e1ae294983e7d/docs/runs/no-such-run/manifest.md
ERROR_RAIL_OK
exit=0

$ bash -c 'out=$(bash skills/architect/ground.sh ground-scripts); git status --porcelain | grep -v "^??" | wc -l | grep -qx 0 && echo READONLY_OK'
READONLY_OK
exit=0
```

In-worktree items 2/3/6 context, recorded for the grader: both executors
here emit `UNGRADED: s1-ground` -> `GROUND: DRIFT ...` exit=3, which the
ruling names correct detection (this worktree holds `s1-ground-01.md` with
`s1-ground-checkrun.md` committed only at 6844877, ahead of this worktree's
frozen HEAD 44d3ce9).

Boundary compliance unchanged: touched only the two scripts and this report;
no commits; temp worktree under `.architect/tmp/` created and removed;
final `git status --porcelain` shows only the job's untracked files.

## STATUS

STATUS: COMPLETE
