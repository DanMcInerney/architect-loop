# Check: ground-scripts/s4-ship

Purpose: the ship-stage skill exists — one dedicated subagent owns end-of-run
integration after the final review (merges, ship-time conflict resolution,
PR prep, digest draft); the orchestrator only dispatches and rules.
Spec: docs/spec/ground-scripts.md (Amendment)
Fix contract: a failure means a missing rule or budget — fix
`skills/ship/SKILL.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/ship/SKILL.md` -> exit:0
- RUN: `grep -F -q "name: ship" skills/ship/SKILL.md` -> exit:0
- RUN: `bash -c 'for t in "final review" "conflict" "Closes #" "digest" "postflight"; do grep -qi "$t" skills/ship/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo RULES_OK'` -> exit:0 match:"RULES_OK"
- RUN: `bash -c 'grep -qi "ship time" skills/ship/SKILL.md && echo SHIPTIME_OK'` -> exit:0 match:"SHIPTIME_OK"
- RUN: `bash -c 'n=$(wc -l < skills/ship/SKILL.md); test "$n" -le 90 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/ship/SKILL.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Reviewer intent items (final review):
- Ship subagent scope: runs AFTER the final review merges; handles remaining
  merges + conflicts at ship time only (mid-run conflicts remain
  decomposition failures — states this); prepares the PR (Closes
  #<tracking-issue>, per-issue back-links) or markdown-mode finish; drafts
  the digest for the orchestrator to post; never approves its own work —
  the orchestrator rules on the result and posts tracker comments.
- Backend-agnostic wording (Claude Agent-tool or codex exec dispatch);
  evidence-grounded reporting; codebase-design glossary exactly.
