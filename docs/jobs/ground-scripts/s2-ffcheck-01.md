# Job report: ground-scripts/s2-01 (ffcheck.ps1/.sh)

Issue: #131. Spec: `docs/spec/ground-scripts.md`. Frozen check:
`docs/checks/ground-scripts/s2-ffcheck.md` (read-only, unmodified).

## Worktree sync

Worktree HEAD was `77dfe1f` at job start (behind the freeze). Verified
ancestry and fast-forwarded:

```
$ git log --oneline -1
77dfe1f Merge pull request #128 from DanMcInerney/terse/architect-core

$ git merge-base --is-ancestor HEAD 44d3ce9; echo exit=$?
exit=0

$ git merge --ff-only 44d3ce9
Updating 77dfe1f..44d3ce9
Fast-forward
 docs/checks/ground-scripts/s1-ground.md  | 27 +++++++++++++
 docs/checks/ground-scripts/s2-ffcheck.md | 21 ++++++++++
 docs/checks/ground-scripts/s3-wiring.md  | 22 +++++++++++
 docs/runs/ground-scripts/manifest.md     | 13 ++++++
 docs/spec/ground-scripts.md              | 68 ++++++++++++++++++++++++++++++++
 5 files changed, 151 insertions(+)
```

HEAD after: `44d3ce9`.

## PHASE 0

Plan and disagreements were posted as a comment on issue #131 before any
implementation:
https://github.com/DanMcInerney/architect-loop/issues/131#issuecomment-4893426778

One item flagged there (RUN item 4's `git checkout -qw 2>/dev/null` line
looking like a typo before the correct `git checkout -q w`) turned out to be
harmless dead code, not a defect — the frozen fixture produced the intended
DIVERGED state verbatim (see below), so no substitution was needed.

## Build

Created (new files only, matching MAY TOUCH):
- `skills/architect/ffcheck.sh`
- `skills/architect/ffcheck.ps1`

Both take one positional arg `<expected-sha>`, run from any cwd inside a git
worktree (git itself resolves refs relative to the discovered repo; no `-C`
needed). Contract implemented identically in both:
- unresolvable/missing arg -> exit 5 `FFCHECK: ERROR <why>`
- `HEAD == git rev-parse --verify <sha>^{commit}` -> exit 0 `FFCHECK: OK
  <short-sha>`, no mutation
- else if `git merge-base --is-ancestor HEAD <sha>` -> `git merge --ff-only
  <sha>` -> exit 0 `FFCHECK: OK <short-sha>`
- else -> exit 2 `FFCHECK: DIVERGED head=<short> expected=<short>`, no merge

Style mirrors `skills/architect/preflight.sh`/`.ps1`: bash uses `set -u` +
small helper functions + `printf` typed-line output; PowerShell uses a
`GitRun` helper returning `{Code, Lines}`, `Write-Output` for the typed
line, explicit `exit <n>`.

## Own tests (seam: the CLI — argv + exit code + stdout line)

Ran a standalone assertion script (14 checks) covering both executors,
including scenarios beyond the frozen check: already-at-head with an
explicit no-mutation assertion, fast-forward applied from a **nested cwd**
(worktree-anywhere requirement), diverged with an explicit no-mutation
assertion, bad-sha ERROR, and missing-arg ERROR. Fixtures built under
`.architect/tmp/` (gitignored via `.gitignore:19 /.architect/`).

```
PASS: sh: already-at-head OK (exit=0 out=FFCHECK: OK 0a076d5)
PASS: sh already-at-head no mutation
PASS: ps: already-at-head OK (exit=0 out=FFCHECK: OK 0a076d5)
PASS: ps already-at-head no mutation
PASS: sh: ff-applied OK from nested cwd (exit=0 out=FFCHECK: OK bc83fd0)
PASS: sh ff mutation landed
PASS: ps: ff-applied OK from nested cwd (exit=0 out=FFCHECK: OK 54a7f4a)
PASS: ps ff mutation landed
PASS: sh: diverged (exit=2 out=FFCHECK: DIVERGED head=f270e24 expected=f607a39)
PASS: sh diverged no mutation
PASS: ps: diverged (exit=2 out=FFCHECK: DIVERGED head=6f7d256 expected=764692d)
PASS: ps diverged no mutation
PASS: sh: bad sha ERROR (exit=5 out=FFCHECK: ERROR unresolvable sha not-a-real-sha)
PASS: ps: bad sha ERROR (exit=5 out=FFCHECK: ERROR unresolvable sha not-a-real-sha)
PASS: sh: missing arg ERROR (exit=5 out=FFCHECK: ERROR missing expected-sha arg)
PASS: ps: missing arg ERROR (exit=5 out=FFCHECK: ERROR missing expected-sha arg)
----
ALL OWN TESTS PASS
```
Exit code of the assertion harness: `0`.

## Frozen check RUN items (run verbatim, from worktree root)

1. `test -f skills/architect/ffcheck.ps1 -a -f skills/architect/ffcheck.sh`
   -> exit `0` (expected `exit:0`) — PASS

2. `bash -c 'bash skills/architect/ffcheck.sh $(git rev-parse HEAD) | grep -q "FFCHECK: OK" && echo AT_HEAD_OK'`
   -> stdout `AT_HEAD_OK`, exit `0` (expected `exit:0 match:"AT_HEAD_OK"`) — PASS

3. `bash -c 'r=.architect/tmp/ffx; rm -rf $r; git init -q $r; cd $r; git commit -qm a --allow-empty; git commit -qm b --allow-empty; s=$(git rev-parse HEAD); git checkout -qb w HEAD~1; bash "$OLDPWD/skills/architect/ffcheck.sh" $s | grep -q "FFCHECK: OK" && test "$(git rev-parse HEAD)" = "$s" && echo FF_APPLIED_OK'`
   -> stdout `FF_APPLIED_OK`, exit `0` (expected `exit:0 match:"FF_APPLIED_OK"`) — PASS

4. `bash -c 'r=.architect/tmp/ffd; rm -rf $r; git init -q $r; cd $r; git commit -qm a --allow-empty; git checkout -qb w; git commit -qm div --allow-empty; git checkout -q master 2>/dev/null || git checkout -q main; git commit -qm other --allow-empty; s=$(git rev-parse HEAD); git checkout -qw 2>/dev/null; git checkout -q w; bash "$OLDPWD/skills/architect/ffcheck.sh" $s; test $? -eq 2 && echo DIVERGED_OK'`
   -> stdout:
   ```
   FFCHECK: DIVERGED head=c2bda65 expected=b024df9
   DIVERGED_OK
   ```
   exit `0` (expected `exit:0 match:"DIVERGED_OK"`) — PASS. (The `git checkout
   -qw 2>/dev/null` line is dead/no-op — `-qw` is not a valid combined flag,
   the error is swallowed, and the following `git checkout -q w` is what
   actually sets branch `w` current — but the fixture still lands on the
   intended diverged state, so the frozen check's own recipe is not
   defective; no substitution needed, flagged in PHASE 0 out of caution.)

5. `bash -c 'bash skills/architect/ffcheck.sh not-a-sha 2>&1; test $? -eq 5 && echo ERROR_OK'`
   -> stdout:
   ```
   FFCHECK: ERROR unresolvable sha not-a-sha
   ERROR_OK
   ```
   exit `0` (expected `exit:0 match:"ERROR_OK"`) — PASS

6. `bash -c 'powershell -NoProfile -ExecutionPolicy Bypass -File skills/architect/ffcheck.ps1 $(git rev-parse HEAD) | grep -q "FFCHECK: OK" && echo PS_OK'`
   -> stdout `PS_OK`, exit `0` (expected `exit:0 match:"PS_OK"`) — PASS

All 6 RUN items: PASS (6/6).

## Reviewer intent items (self-check against s2-ffcheck.md)

- Ancestry via `merge-base --is-ancestor` before any merge: yes, in both
  scripts, gated before the `merge --ff-only` call.
- `--ff-only` is the only mutation: yes; the already-at-head and DIVERGED
  paths never call `git merge`.
- DIVERGED never merges: confirmed by own-test no-mutation assertions
  (HEAD before == HEAD after in the diverged fixture, both executors).
- Identical typed lines across the pair: same `FFCHECK: OK/DIVERGED/ERROR`
  formats, same short-sha rendering (`git rev-parse --short`), verified by
  own tests running the same fixtures through both scripts.
- Works from any cwd inside a worktree: own-test fast-forward scenario runs
  the script from a nested `sub/dir` cwd two levels below the fixture repo
  root, for both executors, and succeeds.

## Post-run repo state check

```
$ git status --short
?? skills/architect/ffcheck.ps1
?? skills/architect/ffcheck.sh

$ git log --oneline -1
44d3ce9 run ground-scripts: spec, manifest, freeze checks s1-s3
```

No commits made. Only the two new files under `skills/architect/` and this
report exist as changes; `docs/checks/**` untouched.

## Boundaries

Touched: `skills/architect/ffcheck.sh`, `skills/architect/ffcheck.ps1`,
`docs/jobs/ground-scripts/s2-ffcheck-01.md`. Nothing else.

## Mirror

Posting this STATUS + summary as a comment on issue #131 via `gh issue
comment`.

STATUS: COMPLETE
