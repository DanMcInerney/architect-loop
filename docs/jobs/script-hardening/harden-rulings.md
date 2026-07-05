# Rulings: script-hardening/harden (issue #96)

Append-only; orchestrator-owned.

- 2026-07-05 RULING on PHASE-0 item 1 (report path outside MAY TOUCH):
  docs/jobs/<run>/ artifacts are exempt bookkeeping (standing ruling from run
  multi-run, docs/jobs/multi-run/s2-skilltext-rulings.md). Not a violation.
- 2026-07-05 RULING on concern 2 (.sh pair not executed in the Windows codex
  sandbox): sanctioned - the dispatch block itself set that policy (MSYS2
  binaries die under the sandbox token, Win32 error 5). The .ps1 path is
  executed by the fixture; .sh parity is by pattern review here and covered
  on POSIX by the same fixture (platform-native selection). Judges in the
  same sandbox grade .sh by reading and record the substitution.
