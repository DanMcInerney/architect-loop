# Check: ground-scripts/s2-ffcheck

Purpose: ffcheck.ps1/.sh exist and implement the FIRST-ACTION contract:
0 `FFCHECK: OK <sha>` (already-at or fast-forwarded), 2 `FFCHECK: DIVERGED`
(never merges), 5 `FFCHECK: ERROR`.
Spec: docs/spec/ground-scripts.md
Fix contract: a failure means a missing pair or wrong typed behavior — fix
`skills/architect/ffcheck.ps1|.sh` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/architect/ffcheck.ps1 -a -f skills/architect/ffcheck.sh` -> exit:0
- RUN: `bash -c 'bash skills/architect/ffcheck.sh $(git rev-parse HEAD) | grep -q "FFCHECK: OK" && echo AT_HEAD_OK'` -> exit:0 match:"AT_HEAD_OK"
- RUN: `bash -c 'r=.architect/tmp/ffx; rm -rf $r; git init -q $r; cd $r; git commit -qm a --allow-empty; git commit -qm b --allow-empty; s=$(git rev-parse HEAD); git checkout -qb w HEAD~1; bash "$OLDPWD/skills/architect/ffcheck.sh" $s | grep -q "FFCHECK: OK" && test "$(git rev-parse HEAD)" = "$s" && echo FF_APPLIED_OK'` -> exit:0 match:"FF_APPLIED_OK"
- RUN: `bash -c 'r=.architect/tmp/ffd; rm -rf $r; git init -q $r; cd $r; git commit -qm a --allow-empty; git checkout -qb w; git commit -qm div --allow-empty; git checkout -q master 2>/dev/null || git checkout -q main; git commit -qm other --allow-empty; s=$(git rev-parse HEAD); git checkout -qw 2>/dev/null; git checkout -q w; bash "$OLDPWD/skills/architect/ffcheck.sh" $s; test $? -eq 2 && echo DIVERGED_OK'` -> exit:0 match:"DIVERGED_OK"
- RUN: `bash -c 'bash skills/architect/ffcheck.sh not-a-sha 2>&1; test $? -eq 5 && echo ERROR_OK'` -> exit:0 match:"ERROR_OK"
- RUN: `bash -c 'powershell -NoProfile -ExecutionPolicy Bypass -File skills/architect/ffcheck.ps1 $(git rev-parse HEAD) | grep -q "FFCHECK: OK" && echo PS_OK'` -> exit:0 match:"PS_OK"

Reviewer intent items (final review):
- Ancestry via merge-base --is-ancestor before any merge; --ff-only is the
  only mutation; DIVERGED never merges; identical typed lines across the
  pair; works from any cwd inside a worktree.
