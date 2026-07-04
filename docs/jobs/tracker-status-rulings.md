# Rulings: tracker-status (orchestrator-owned, append-only)

- 2026-07-04 first judgment: checks integrity PASS, but diff-vs-intent FAIL
  - the markdown-backend refactor removed status.sh's literal UTF-8 phase
  glyphs, regressing the PRIOR frozen contract (status-scripts SS1 and the
  validator's check_status_contract require the glyph literals in both
  scripts). Respawn ruling: restore the seven glyph literals in status.sh
  (sh carries literals; only ps1 may use [char] forms), change nothing else
  beyond what TS checks require, re-run the FULL SS suite (docs/checks/
  status-scripts.md) plus TS1-TS6 and record verbatim output.
- 2026-07-04 composite catch (post-merge, sh live run): has_num() is
  broken for the LAST list entry - it wraps the list via printf inside a
  command substitution, and $(...) strips trailing newlines, so the
  terminal entry never matches *\n<n>\n*. Live evidence: opens=[7,9,10]
  but has_num(...,10)=N -> issue 9 rendered READY instead of QUEUED.
  Latent second manifestation: a single-child tracking issue would
  false-negative into NOOPENRUN (TRACK selection worked here only because
  duplicate parent entries supplied interior newlines). Respawn ruling:
  reimplement has_num without command substitution (e.g. case pattern over
  $'\n'"$1" with $1's own trailing newline, or grep -qx), verify BOTH call
  sites (blocker filter, TRACK selection incl. a single-child fixture),
  re-run TS1-TS6. ps1 unaffected (rendered correctly live).
