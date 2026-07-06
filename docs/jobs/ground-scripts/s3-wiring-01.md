# Job report: ground-scripts/s3-01 (wiring: ground/ffcheck contracts + SKILL/loop/dispatch delegation)

Issue: #132 (`ground-scripts s3-wiring`, tracking #129). Spec:
`docs/spec/ground-scripts.md`. Frozen check:
`docs/checks/ground-scripts/s3-wiring.md` (read-only, unmodified — diffed
against HEAD, no changes; see `git diff --stat` below).

## Worktree sync (FIRST ACTION)

```
$ bash skills/architect/ffcheck.sh fa9f5474b546984dae13eed530cb18a86f40d8e0
```
`ffcheck.sh` was not present at job start (this worktree predated the merge
that shipped it), so per the fallback instructions I verified ancestry and
fast-forwarded manually first:

```
$ git merge-base --is-ancestor HEAD fa9f5474b546984dae13eed530cb18a86f40d8e0
ancestor-check-exit: 0

$ git merge --ff-only fa9f5474b546984dae13eed530cb18a86f40d8e0
Updating 77dfe1f..fa9f547
Fast-forward
 docs/checks/ground-scripts/s1-ground.md         |  27 +++
 docs/checks/ground-scripts/s2-ffcheck.md        |  21 ++
 docs/checks/ground-scripts/s3-wiring.md         |  22 ++
 docs/jobs/ground-scripts/s1-ground-01.md        | 302 ++++++++++++++++++++++++
 docs/jobs/ground-scripts/s1-ground-checkrun.md  |  63 +++++
 docs/jobs/ground-scripts/s1-ground-rulings.md   |  17 ++
 docs/jobs/ground-scripts/s2-ffcheck-01.md       | 170 +++++++++++++
 docs/jobs/ground-scripts/s2-ffcheck-checkrun.md |  51 ++++
 docs/runs/ground-scripts/manifest.md            |  13 ++
 docs/spec/ground-scripts.md                     |  68 ++++++
 skills/architect/ffcheck.ps1                    |  49 ++++
 skills/architect/ffcheck.sh                     |  28 +++
 skills/architect/ground.ps1                     | 290 +++++++++++++++++++++++
 skills/architect/ground.sh                      | 277 ++++++++++++++++++++++
 14 files changed, 1398 insertions(+)

$ bash skills/architect/ffcheck.sh fa9f5474b546984dae13eed530cb18a86f40d8e0
FFCHECK: OK fa9f547
```
Exit `0` after the fast-forward. HEAD after: `fa9f547`.

## PHASE 0

Posted as a comment on issue #132 before finalizing the build:
https://github.com/DanMcInerney/architect-loop/issues/132#issuecomment-4893755947

Two items flagged there:
1. The spec (`docs/spec/ground-scripts.md:37-38`) claims ffcheck "Replaces
   the three-line FIRST-ACTION prose in dispatch blocks," but no such prose
   exists in `dispatch.md`'s committed history
   (`git log -p --all -- skills/architect/dispatch.md | grep -i
   "FIRST-ACTION\|merge-base\|ff-only"` returns nothing) — it only ever
   existed ad hoc (this job's own dispatch message; `s2-ffcheck-01.md`'s
   "Worktree sync" section). Not a blocker: added the one-line FIRST ACTION
   as new codified text rather than "replacing" nonexistent history.
2. Frozen RUN item 3 (`grep -qi "ground" skills/architect/loop.md`) would
   pass even pre-edit on the substring "background"/"backgrounded"
   (loop.md:50,66,78,82 pre-edit) — a weak check design, but `docs/checks/**`
   is read-only so I did the substantive wiring anyway (both
   frontier-recompute mentions now explicitly name `ground.ps1|.sh`'s
   `FRONTIER:` line).

No other disagreements.

## Build

### 1. `tests/validate_skills.py`

Added `ground_executor_cases()`, `build_ground_ok_fixture()`,
`check_ground_contract()`, `ffcheck_executor_cases()`,
`check_ffcheck_contract()`, following the `check_check_runner_fixture` /
`check_postflight_lane_fixture` fixture-run pattern (real subprocess
invocations against a built fixture, not string-presence grep). Wired both
into `main()` immediately after `check_check_runner_fixture()`. Did not
restructure any existing passing check.

- `check_ground_contract()`: asserts both `ground.ps1`/`ground.sh` exist;
  runs each with no args from `ROOT` (expect exit 5, `GROUND: ERROR`); builds
  a markdown-tracker fixture repo under
  `.architect/tmp/ground-contract-fixture` (tracking issue #1 OPEN, one
  open/unblocked child #2, `docs/checks/fixrun/` committed with no further
  edits) and runs each script against it (expect exit 0, `FRONTIER:` line
  and `GROUND: OK` summary present).
- `check_ffcheck_contract()`: asserts both `ffcheck.ps1`/`ffcheck.sh` exist;
  runs each with a bad sha (expect exit 5, `FFCHECK: ERROR`) and with the
  worktree's actual `HEAD` sha (expect exit 0, `FFCHECK: OK`) — no separate
  fixture repo needed since at-HEAD never mutates.
- Both follow the existing `check_runner_cases()` precedent of gating bash
  cases off on Windows (`bash and os.name != "nt"`) so only the runnable
  executor(s) on the current machine are exercised.

### 2. `skills/architect/SKILL.md` `### 0. Ground`

Replaced the reconcile bullet (manifest load + tracker/git reconcile) and
the STOP-gate bullet with one delegation bullet naming `ground.ps1|.sh`'s
five typed exits (0 OK / 2 STOP / 3 DRIFT / 5 ERROR) and its `FRONTIER:`
line. Kept the authority-order bullet and the model-resolution bullet
unchanged, word-for-word.

### 3. `skills/architect/loop.md`

Two frontier-recomputation mentions (`## Factory block procedure` step 3's
Job DONE bullet, and step 4 "Recompute the ready issues") now name
`ground.ps1|.sh <run>`'s `FRONTIER:` line as the source of the ready-issue
set. Dispatch-first ordering (recompute-and-dispatch happens before grading)
is unchanged — only inserted the script pointer into the existing sentences.

### 4. `skills/architect/dispatch.md`

Added one `FIRST ACTION -` line to the `## Builder block template`, directly
after "Execute the architect spec below. Operating rules:" and before
"PHASE 0 -": `bash skills/architect/ffcheck.sh <dispatch-head-sha>`
(PowerShell alternate named) with the three typed-exit dispositions (0
proceed / 2 stop-and-report / 5 stop-and-report). No other line in the file
was touched — every existing fenced block, heading, and marker used by
`check_model_alias_table`, `check_config_example`, and
`check_check_runner_dispatch_contract` is byte-identical to before.

## Own tests at the seam (tdd skill — the CLI: argv + exit code + stdout)

Red/green demonstration that `check_ground_contract`/`check_ffcheck_contract`
detect real defects rather than passing by construction — each script was
temporarily moved out of `skills/architect/`, the full suite run, then the
script restored and the suite re-run green:

```
$ mv skills/architect/ground.sh .architect/tmp/ground.sh.hidden
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run python tests/validate_skills.py
FAIL - 1 problem(s):
  - skills\architect\ground.sh: missing ground script
exit=1
$ mv .architect/tmp/ground.sh.hidden skills/architect/ground.sh
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run python tests/validate_skills.py 2>&1 | tail -1
OK - 9 skills validated, v4 contracts clean

$ mv skills/architect/ffcheck.sh .architect/tmp/ffcheck.sh.hidden
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run python tests/validate_skills.py
FAIL - 1 problem(s):
  - skills\architect\ffcheck.sh: missing ffcheck script
exit=1
$ mv .architect/tmp/ffcheck.sh.hidden skills/architect/ffcheck.sh
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run python tests/validate_skills.py 2>&1 | tail -1
OK - 9 skills validated, v4 contracts clean
```

Post-restore diff confirms the scripts themselves are byte-identical to the
merged frozen originals (untouched by the red/green demo):

```
$ git diff --stat -- skills/architect/ground.sh skills/architect/ground.ps1 skills/architect/ffcheck.sh skills/architect/ffcheck.ps1
(no output)
```

## Frozen check RUN items (run verbatim, from worktree root, executor: bash / Git Bash)

1. `bash -c 'grep -q "ground.ps1\|ground.sh" skills/architect/SKILL.md && echo SKILL_WIRED'`
   -> stdout `SKILL_WIRED`, exit `0` (expected `exit:0 match:"SKILL_WIRED"`) — PASS
2. `bash -c 'grep -qi "ffcheck" skills/architect/dispatch.md && echo DISPATCH_WIRED'`
   -> stdout `DISPATCH_WIRED`, exit `0` (expected `exit:0 match:"DISPATCH_WIRED"`) — PASS
3. `bash -c 'grep -qi "ground" skills/architect/loop.md && echo LOOP_WIRED'`
   -> stdout `LOOP_WIRED`, exit `0` (expected `exit:0 match:"LOOP_WIRED"`) — PASS
4. `bash -c 'grep -q "check_ground_contract\|ground.ps1" tests/validate_skills.py && grep -qi "ffcheck" tests/validate_skills.py && echo VALIDATOR_WIRED'`
   -> stdout `VALIDATOR_WIRED`, exit `0` (expected `exit:0 match:"VALIDATOR_WIRED"`) — PASS
5. `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'`
   -> stdout `OK - 9 skills validated, v4 contracts clean`, exit `0` (expected `exit:0 match:"OK"`) — PASS
6. `bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'`
   -> stdout `LINES_OK 214`, exit `0` (expected `exit:0 match:"LINES_OK"`) — PASS

All 6 RUN items: PASS (6/6).

## Reviewer intent items (self-check against s3-wiring.md)

- SKILL.md Ground bullets and loop.md frontier/dispatch lines delegate to
  the scripts: yes — the Ground section's reconcile/STOP prose is replaced
  by one bullet naming the script and its typed exits; both loop.md
  frontier-recompute mentions now name `ground.ps1|.sh`'s `FRONTIER:` line.
  Prose shrank (SKILL.md's Ground section: 2 replaced bullets -> 1
  delegation bullet); the procedure (reconcile logic, STOP gates, frontier
  computation) lives only in `ground.sh`/`.ps1`, not duplicated in prose.
- Dispatch blocks' FIRST-ACTION is one ffcheck command: yes — one
  `FIRST ACTION -` line naming `ffcheck.sh`/`.ps1` with the dispatch-head-sha
  placeholder, in `## Builder block template`.
- Validator checks the typed contracts, not merely string presence: yes —
  `check_ground_contract`/`check_ffcheck_contract` run real subprocesses
  (no-args, bad-sha, at-head, and a built OK fixture) and assert exit codes
  plus typed-line substrings, per the red/green demonstration above.
- Five-file guard stays <=989 non-blank: combined total after all edits is
  957 (SKILL.md 179 + dispatch.md 503 + loop.md 132 + tracker.md 66 +
  research.md 77), under the 989 cap; confirmed both directly (`grep -cv`
  per file, summed) and via the validator's own `check_skill_text_size`
  passing in RUN item 5's full-suite run.

## Post-run repo state check

```
$ git status --short
 M skills/architect/SKILL.md
 M skills/architect/dispatch.md
 M skills/architect/loop.md
 M tests/validate_skills.py

$ git diff --stat -- docs/checks/
(no output — docs/checks/ untouched)
```

No commits made. Only the four MAY-TOUCH files plus this report changed.

## Boundaries

Touched: `tests/validate_skills.py`, `skills/architect/SKILL.md`,
`skills/architect/loop.md`, `skills/architect/dispatch.md`,
`docs/jobs/ground-scripts/s3-wiring-01.md`. Nothing else.

## Mirror

Posting this STATUS + summary as a comment on issue #132 via `gh issue
comment`.

STATUS: COMPLETE
