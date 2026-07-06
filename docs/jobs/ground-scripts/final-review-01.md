# Final review: run ground-scripts

Reviewer: fresh final-review subagent (built nothing in this run). Worktree
fast-forwarded to freeze `4aa2574c3a709a630889f37754d59e5d8315ba08`
(`ffcheck.sh` absent pre-FF, fallback used: `merge-base --is-ancestor` exit 0,
`merge --ff-only` -> HEAD `4aa2574`). Review basis:
`docs/spec/ground-scripts.md` (incl. Amendment) -> run diff
(`git diff 77dfe1f..HEAD`, 26 files, +2597/-13) -> issues #129-#134 ->
`docs/jobs/ground-scripts/s1-ground-rulings.md`.

## Axis 1 — Spec findings

**S1 (P1, FIXED): ground pair diverges and ground.ps1 exits UNTYPED on an
unresolvable recorded freeze SHA.** Scenario: the tracking-issue body records
a well-formed freeze SHA that resolves to no commit (typo, truncation, or a
SHA quoted from elsewhere). Reproduced on the markdown fixture, identical
state, shipped scripts: `ground.sh` -> exit 3
`GROUND: DRIFT docs/checks/fixrun/ changed since freeze 1234567890abcdef1234`
(misleading fact — the checks did not change; git's stderr was captured by
`2>&1` into `freeze_diff`); `ground.ps1` -> **exit 1, zero `GROUND:` lines**
(`grep -c "GROUND:"` = 0): the one native git call left outside the builder's
own `GitTry` wrapper (`$freezeShort = & git ... rev-parse --short ...`,
ground.ps1:286 pre-fix) raises a terminating `NativeCommandError` under
`$ErrorActionPreference = "Stop"` — the exact PS 5.1 gotcha the s1 report
documented and fixed everywhere else. A second divergence trigger: the freeze
regex separator classes differed (`[^0-9a-zA-Z]*` in sh vs `[^0-9a-fA-F]*` in
ps1), so a body like `freeze xyz4aa2574aa` made ps1 capture a bogus SHA while
sh fell back to `git log` — reproduced: ps1 crashed, sh printed `GROUND: OK`.
Violates s1's intent item ".ps1 and .sh emit identical typed lines for
identical state" and the typed-exit contract (0/2/3/5, summary always last).
Fixed (three coordinated edits, verified identical typed lines + exits on all
three fixture states, both executors):

- `skills/architect/ground.ps1:212` — separator class aligned to sh
  (`[^0-9a-zA-Z]*`).
- `skills/architect/ground.ps1:215-227` — explicit resolvability gate:
  unresolvable recorded freeze -> `GROUND: DRIFT recorded freeze <sha> not
  resolvable to a commit`, exit 3.
- `skills/architect/ground.ps1:293-296` — `rev-parse --short` wrapped in
  `GitTry` (crash rail removed).
- `skills/architect/ground.sh:213-216` — same resolvability gate, so sh's
  misleading changed-since-freeze DRIFT becomes the accurate fact line.

**S2 (P1, FIXED in the mutable suite): the run-isolation regression test did
not pin marker-scoped reads.** Spec Amendment for s5: "run-isolation
regression test pinning marker-scoped reads." Proven gap: a mutant deleting
the `contains("<!-- architect-run: ... -->")` clause from ground.ps1's
github-mode jq filter survived the FULL validator suite (`OK - 10 skills
validated`, exit 0). The shipped fixture is markdown-tracker, where isolation
is directory+parent scoped (consistent with `status.sh` and `tracker.md`) and
the marker is never read; gh's `--jq` runs inside gh, so no fixture can
execute the github filter. Fixed: `check_run_isolation` now pins both scoping
clauses (`.parent.number == ` and `contains("<!-- architect-run: `) at file
level in BOTH scripts (`tests/validate_skills.py:1296-1315`), with the
rationale in a comment. Falsifiability: mutant re-seeded after the fix ->
`FAIL - 1 problem(s): ... lost its 'contains("<!-- architect-run: ' scoping
clause`, exit 1; restored -> OK.

**S3 (P1, orchestrator-owned — not fixable from this worktree): the s4-ship
checkrun artifact was never committed, so ground DRIFTs at the run's own
head.** Every other slice has a `run ground-scripts: checkrun evidence`
commit (`137be15` s1, s2/s3 equivalents, `9677475` s5); s4 has none —
`git log --all -- docs/jobs/ground-scripts/s4-ship-checkrun.md` is empty,
while issue #133's close comment claims "MERGED on green checkrun (6/6,
integrity true)". Reproduced at HEAD `4aa2574` (synced with origin), both
executors byte-identical: `UNGRADED: s4-ship` -> `GROUND: DRIFT ungraded job
report(s) present without checkrun evidence`, exit 3. The shipped detector is
working correctly; the run's bookkeeping violates loop.md's "commit the
checkrun artifact" step. Remediation is a commit (orchestrator-owned; this
review does not commit and will not fabricate grading evidence): commit
`docs/jobs/ground-scripts/s4-ship-checkrun.md` or record a ruling.

**S4 (P2, recorded — no code fix): ground's ungraded matcher flags report
classes that never receive checkrun evidence.** `*-NN.md` reports pair with
`<slug>-checkrun.md`; a final-review report (this file, per the dispatch's
own naming `final-review-01.md`) has no frozen check and never gets one, so
every post-review Ground returns DRIFT until ruled. This is spec-conformant
("flag job reports in docs/jobs/<run>/ lacking checkrun evidence"; non-goal:
"no judgment in scripts"), so the fix would be spec-level (an exemption
convention), not a script edit. One line for the digest.

## Axis 2 — Cohesion findings

**C1 (P2, recorded — raw evidence left unedited): s5's job report ends
`STATUS: PASS`,** off the report grammar (`COMPLETE |
COMPLETE_WITH_CONCERNS | BLOCKED`) that s1-s4 all follow
(`docs/jobs/ground-scripts/s5-ship-wiring-01.md:101`). Rewriting a builder's
raw-evidence artifact post-hoc would falsify the record, so it stays; the
codex-backend substitutions in that report were audited instead (below).

**C2 (P2, recorded — frozen check read-only): s3's RUN item 3
(`grep -qi "ground" skills/architect/loop.md`) passes on pre-edit text** via
"background"/"backgrounded" (s3 report PHASE 0 flagged it; confirmed:
`git show 77dfe1f:skills/architect/loop.md | grep -ci ground` = 4, all
"background*"). The substantive wiring is real regardless — both loop.md
frontier-recompute sentences name `ground.ps1|.sh <run>`'s `FRONTIER:` line
(loop.md:28, 42-44). Known lesson class (never freeze greps colliding with
existing substrings); check files are read-only, digest line only.

**Cohesion walk, remainder clean:** no duplicated concepts (the
scripts' standalone `fm`/arg-parse conventions deliberately mirror
`status.sh` precedent; `run_isolation_executor_cases` aliases
`ground_executor_cases`); glossary lint green across all 10 skills incl. new
`ship`; no interface drift between SKILL.md `### 5. Finish`, `skills/ship/
SKILL.md`, and loop.md; SKILL.md was touched by two slices (s3 Ground, s5
Finish) in disjoint sections with consistent voice; old Ground reconcile/STOP
prose fully replaced, not duplicated; no unrequested compat shims.

## Audits ordered by the dispatch

- **s1 ruling items 2/3/6 (green-by-demonstration), reproduced:** matcher fix
  verified in code (`sed 's/-[0-9][0-9]$//'` sh:251 / `-replace
  '-[0-9][0-9]$', ''` ps1:262) and by mutant (reverting it reproduces the
  exact s1 defect: `UNGRADED: slice-a-01` on a correctly paired report).
  Clean-state demonstration re-run post-fix on a paired-report fixture, both
  executors, byte-identical: `FRONTIER: 2` + `GROUND: OK issues=0/1
  frontier=1 freeze=afc8bdb`, exit 0 (verbatim in sweep below). In-worktree
  items 2/3/6 DRIFT exactly as the ruling names correct detection — the
  genuinely ungraded `s4-ship` report (S3), plus this report once written.
- **Codex substitutions (s4, s5):** each PowerShell substitution compared
  against its bash RUN item — same-pattern faithful (one soft spot:
  `Select-String -SimpleMatch` is case-insensitive where `grep -qF` is
  case-sensitive). Decisive evidence: this review re-ran ALL s4 and s5 items
  with the real bash executor — 10/10 identical verdicts (s4 6/6 incl.
  `LINES_OK 89`, `NO_ECHO`; s5 wiring items green).
- **Ship skill vs s4 intent items:** all present — runs after final review
  merges or a recorded skip-ruling (SKILL.md:14-16); ship-time-only conflict
  resolution with mid-run conflicts stated as decomposition failures (24-27);
  PR prep `Closes #<tracking-issue>` + per-issue back-links (64-67);
  markdown-mode finish (70-75); digest DRAFT for the orchestrator to post,
  never approves its own work (30-32, 77-79); backend-agnostic (13-15);
  glossary contract exact (81-89).
- **Isolation regression test:** run (validator green); decoy #99 excluded
  from ISSUE:/FRONTIER lines; marker gap found and fixed (S2).

## Fix list (file:line)

| File | Change |
|---|---|
| `skills/architect/ground.ps1:212` | freeze-regex separator parity with sh |
| `skills/architect/ground.ps1:215-227` | resolvability DRIFT gate (typed exit 3) |
| `skills/architect/ground.ps1:293-296` | `GitTry` wrap on `rev-parse --short` (crash fix) |
| `skills/architect/ground.sh:213-216` | resolvability DRIFT gate (accurate fact line) |
| `tests/validate_skills.py:1035-1064` | OK fixture carries a PAIRED report (pins the s1 ruling matcher fix) |
| `tests/validate_skills.py:1150-1229` | ground STOP (exit 2), unpaired-report DRIFT (exit 3), bad-freeze DRIFT (exit 3) cases |
| `tests/validate_skills.py:1296-1315` | github-mode jq scoping-clause pin, both scripts |

Diffstat: `ground.ps1 | 18 +++++----`, `ground.sh | 3 ++`,
`validate_skills.py | 110 +++++-` (3 files, +124/-7).

## Test stewardship table

| Test | Action | Reason class | Proof |
|---|---|---|---|
| ground fixture paired report (OK case) | add | coverage: s1 ruling matcher fix had no regression test | mutant `$slug = $base` (matcher revert) -> `UNGRADED: slice-a-01`, OK case FAIL; restore -> OK |
| ground fixture `stop` case (exit 2) | add | coverage: typed exit 2 untested in mutable suite | mutant removing env gate -> `expected exit 2 got 3`, FAIL; restore -> OK |
| ground fixture `drift` case (exit 3, unpaired) | add | coverage: typed exit 3 untested in mutable suite | same mutant round: matcher revert changes UNGRADED slug; paired-OK case is the sharp assert (above); restore -> OK |
| ground fixture `bad-freeze` case (exit 3) | add | coverage: S1 crash regression | pre-fix ground.ps1 re-seeded -> `expected exit 3 got 1` + missing DRIFT line, FAIL; restore -> OK |
| jq scoping-clause pin (`check_run_isolation`) | add | coverage: S2 marker gap | marker-clause-deletion mutant -> FAIL (was surviving the full suite); restore -> OK |

No rewrites, no deletions. All mutants restored; `git diff` on the two
scripts shows only the S1 fixes.

## Closing sweep (all RUN items, bash executor, worktree root, this session)

s1-ground (7 items):
```
1 test -f ground.ps1 -a -f ground.sh                          exit=0  PASS
2 bash ground.sh ground-scripts                               exit=3  DRIFT (in-worktree context;
    UNGRADED: s4-ship — ruled correct detection; GREEN per s1 ruling, clean-state demo below)
3 ... | grep -c "FRONTIER:"                                   0       (same context; GREEN per ruling)
4 CLAUDE_CODE_SUBAGENT_MODEL=haiku ... STOP_GATE_OK           exit=0  PASS (re-run post-fix)
5 no-such-run -> ERROR_RAIL_OK                                exit=0  PASS (re-run post-fix)
6 powershell ground.ps1 | grep "GROUND: OK"                   exit=1  (same context; GREEN per ruling;
    ps1 output byte-identical to sh incl. DRIFT line)
7 READONLY_OK                                                 exit=0  PASS (clean detached worktree at
    HEAD; re-verified post-fix same-pattern: git status identical before/after both executors)
```
Ruled clean-state demonstration (s1 items 2/3/6), post-fix, verbatim:
```
=== post-fix clean-state demo: bash ===
ISSUE: 1 open blockedBy=none
ISSUE: 2 open blockedBy=none
BRANCH: factory/fixrun missing
FRONTIER: 2
GROUND: OK issues=0/1 frontier=1 freeze=afc8bdb
exit=0
=== post-fix clean-state demo: powershell ===
ISSUE: 1 open blockedBy=none
ISSUE: 2 open blockedBy=none
BRANCH: factory/fixrun missing
FRONTIER: 2
GROUND: OK issues=0/1 frontier=1 freeze=afc8bdb
exit=0
```

s2-ffcheck (6 items):
```
1 pair exists            exit=0 PASS      4 DIVERGED_OK  exit=0 PASS
2 AT_HEAD_OK             exit=0 PASS      5 ERROR_OK     exit=0 PASS
3 FF_APPLIED_OK          exit=0 PASS      6 PS_OK        exit=0 PASS
```

s3-wiring (6 items):
```
1 SKILL_WIRED exit=0  2 DISPATCH_WIRED exit=0  3 LOOP_WIRED exit=0
4 VALIDATOR_WIRED exit=0  5 validator tail -1 "OK - 10 skills validated,
v4 contracts clean" exit=0  6 LINES_OK 217 exit=0        — all PASS
```

s4-ship (6 items, real bash executor — also validates the codex job's
substitutions):
```
1 exit=0  2 exit=0  3 RULES_OK exit=0  4 SHIPTIME_OK exit=0
5 LINES_OK 89 exit=0  6 NO_ECHO exit=0                    — all PASS
```

s5-ship-wiring (4 items):
```
1 FINISH_WIRED exit=0  2 TESTS_WIRED exit=0
3 validator "OK - 10 skills validated, v4 contracts clean" exit=0
4 LINES_OK 217 exit=0                                     — all PASS
```

Final closing validator run (after all fixes and test edits), verbatim:
```
OK - 10 skills validated, v4 contracts clean
exit=0
```

## Totals

- Spec axis: 4 findings — 3 P1 (S1 fixed, S2 fixed, S3 orchestrator-owned
  bookkeeping), 1 P2 (S4, recorded). Worst: S1 (ground.ps1 untyped exit-1
  crash breaking the typed-exit interface the loop rules on).
- Cohesion axis: 2 findings — 2 P2 (C1 STATUS grammar, C2 weak frozen grep),
  0 P1. Worst: C1.
- Fixes applied: 3 files, +124/-7; every graded RUN item green after all
  edits (s1 items 2/3/6 green per the s1 ruling: matcher fix + reproduced
  clean-state demonstration, both executors).

MIRROR: delivered to the orchestrator as the review return message (no
tracker posts per dispatch).

STATUS: GREEN (fixes applied, all RUN items green)
