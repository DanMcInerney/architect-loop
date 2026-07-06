# Check: ground-scripts/s1-ground

Purpose: ground.ps1/.sh exist, emit the typed contract (0 OK + FRONTIER line
/ 2 STOP / 3 DRIFT / 5 ERROR) from real repo state, both executors,
detection-only.
Spec: docs/spec/ground-scripts.md
Fix contract: a failure means a missing pair, wrong typed line/exit, or a
judgment side effect — fix `skills/architect/ground.ps1|.sh` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/architect/ground.ps1 -a -f skills/architect/ground.sh` -> exit:0
- RUN: `bash skills/architect/ground.sh ground-scripts` -> exit:0 match:"GROUND: OK"
- RUN: `bash -c 'bash skills/architect/ground.sh ground-scripts | grep -c "FRONTIER:"'` -> exit:0 match:"1"
- RUN: `bash -c 'CLAUDE_CODE_SUBAGENT_MODEL=haiku bash skills/architect/ground.sh ground-scripts; test $? -eq 2 && echo STOP_GATE_OK'` -> exit:0 match:"STOP_GATE_OK"
- RUN: `bash -c 'bash skills/architect/ground.sh no-such-run 2>&1; test $? -eq 5 && echo ERROR_RAIL_OK'` -> exit:0 match:"ERROR_RAIL_OK"
- RUN: `bash -c 'powershell -NoProfile -ExecutionPolicy Bypass -File skills/architect/ground.ps1 ground-scripts | grep -q "GROUND: OK" && echo PS_OK'` -> exit:0 match:"PS_OK"
- RUN: `bash -c 'out=$(bash skills/architect/ground.sh ground-scripts); git status --porcelain | grep -v "^??" | wc -l | grep -qx 0 && echo READONLY_OK'` -> exit:0 match:"READONLY_OK"

Reviewer intent items (final review; no per-issue model review):
- Manifest parse, tracker child reconcile (github via gh scoped by run
  marker; markdown via docs/issues/<run>/), freeze verification, ungraded
  report detection, both STOP files (incl. --git-common-dir primary), env
  gate, and frontier (open AND all blockers closed) are all present and
  detection-only; one greppable summary line; DRIFT (exit 3) is reachable
  and covers freeze drift and tracker/git disagreement.
- .ps1 and .sh emit identical typed lines for identical state; no tracker
  posts, no file writes, no merges.
