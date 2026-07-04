# Rulings: tracker-status (orchestrator-owned, append-only)

- 2026-07-04 first judgment: checks integrity PASS, but diff-vs-intent FAIL
  - the markdown-backend refactor removed status.sh's literal UTF-8 phase
  glyphs, regressing the PRIOR frozen contract (status-scripts SS1 and the
  validator's check_status_contract require the glyph literals in both
  scripts). Respawn ruling: restore the seven glyph literals in status.sh
  (sh carries literals; only ps1 may use [char] forms), change nothing else
  beyond what TS checks require, re-run the FULL SS suite (docs/checks/
  status-scripts.md) plus TS1-TS6 and record verbatim output.
