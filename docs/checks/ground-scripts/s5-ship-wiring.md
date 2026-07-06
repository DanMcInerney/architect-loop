# Check: ground-scripts/s5-ship-wiring

Purpose: Finish delegates shipping to the `ship` stage skill's subagent; a
regression test pins marker-scoped multi-run isolation; suite green.
Spec: docs/spec/ground-scripts.md (Amendment)
Fix contract: fix `skills/architect/SKILL.md` (### 5. Finish only) and
`tests/validate_skills.py` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -qF "ship" skills/architect/SKILL.md && grep -qi "ship subagent\|ship stage skill" skills/architect/SKILL.md && echo FINISH_WIRED'` -> exit:0 match:"FINISH_WIRED"
- RUN: `bash -c 'grep -qi "isolation\|architect-run" tests/validate_skills.py && grep -qi "ship" tests/validate_skills.py && echo TESTS_WIRED'` -> exit:0 match:"TESTS_WIRED"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"
- RUN: `bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"

Reviewer intent items (final review):
- Finish: after the final review merges, ONE ship subagent (per
  skills/ship/SKILL.md) does remaining merges, ship-time conflicts, PR prep,
  digest draft; the orchestrator dispatches, rules on the result, and posts
  the digest — it no longer performs PR mechanics itself. Mid-run conflict
  doctrine unchanged.
- Isolation regression test: ground's tracker reads accept ONLY children of
  the manifest's tracking issue carrying the run marker (fixture with a
  decoy same-repo issue lacking the marker → excluded from ISSUE:/FRONTIER
  lines); ship skill inventoried in LIBRARY_SKILLS with budget ≤90.
- Five-file guard ≤989; no restructuring of passing tests.
