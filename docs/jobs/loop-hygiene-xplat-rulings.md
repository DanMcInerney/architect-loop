# Rulings: loop-hygiene-xplat (#77) — post-freeze, append-only, orchestrator-owned

## R1 — 2026-07-04 — check-runner bash resolution defect (respawn-with-answer)

First check-runner execution of the frozen xplat checks (evidence head
da73b97) produced 4 defective items NOT attributable to the builder's diff:
the runner's bash executor resolved `bash` to WSL's System32 bash.exe, not
Git Bash. Raw evidence in the first committed
docs/jobs/loop-hygiene-xplat-checkrun.md: `powershell: command not found`
(exit 127), `uv: command not found` (exit 127), and twice `fatal: not a git
repository: /mnt/c/...` (exit 128, WSL git cannot resolve the Windows
worktree pointer). The six `bash -n` items and both `grep -lE` items
executed correctly (bash syntax checking is executor-equivalent).

Ruling: this is a cross-platform defect in `skills/architect/check-runner.ps1`
(FileName = "bash" resolves through PATH where System32 WSL bash shadows Git
Bash on Windows) — inside #77's MAY TOUCH and exactly this slice's subject
matter. Fix the input and respawn a fresh builder on #77 at the same tier:

- In check-runner.ps1, when executor is `bash` on Windows, resolve Git Bash
  explicitly (e.g. sibling `bin\bash.exe` of the resolved `git` command, or
  `$env:ProgramFiles\Git\bin\bash.exe`), never bare `bash` through PATH;
  fail loudly with `CHECKRUN: ERROR` if no Git Bash is found — no silent
  fallback to WSL. Record the resolved executor path in the evidence header.
- check-runner.sh needs no change (POSIX bash is unambiguous); audit-note it.
- The parity table gains a row for this finding.

The defective evidence file is superseded; the runner will be re-executed
after the respawned lane commits, and the refreshed evidence file replaces
the same path (precedent: run #68 quoting-defect refresh).

Boundaries unchanged from #77. The frozen check file is unchanged and
unaffected (its commands were correct; the runner resolution was not).

## R2 — 2026-07-04 — first judgment FAIL overruled as two frozen-check text defects; corrected-anchor re-judgment

Judgment #1 (fresh codex judge, refreshed evidence) returned slice FAIL on:
- J3: `A docs/jobs/loop-hygiene-xplat-01.md` in the diff. Diagnosis: check
  authoring defect — the frozen J3 omitted the standard bookkeeping
  exemption for the job's own required report (same defect class as the
  v4-cleanup first judgment; postflight exempts docs/jobs/ for the same
  reason). The builder was required by issue #77 and the dispatch block to
  write exactly that file.
- J4: flagged `find -maxdepth` (status.sh:18,19,74) as GNU-only. Diagnosis:
  factually incorrect and outside the frozen flag list — BSD/macOS find
  supports `-maxdepth`; the frozen list named date, sed -i, find -printf,
  grep -P, tail --, ps field specs only.

Correction: judge-only text of J3/J4 amended on the factory branch (this
commit). RUN items are byte-identical between the frozen version at
cbfb4734 and the corrected version — the committed checkrun evidence
(head 24edb71, executor_resolved Git Bash) remains valid. Checks-integrity
semantics are unchanged: the correction is an orchestrator commit on the
factory branch; the job branch still contains no docs/checks/ edits.

A fresh judge (judgment #2) is dispatched against the same evidence with
this ruling in its intent context. The orchestrator did not overturn a
verdict on the merits; it corrected defective check text and ordered a new
independent judgment (os-docs corrected-anchor precedent).
