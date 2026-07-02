# Gates — slice `v4-cleanup` re-judgment (`v4-cleanup2`)

Frozen BEFORE the re-judgment dispatch. Read-only for everyone. Any edit to
this file after this freeze is an automatic FAIL.

Provenance: `docs/gates/v4-cleanup.md` (freeze 9c670b5) was judged FAIL on
2026-07-02 solely on two mechanization defects in the gate text itself, per
the cold judge's verdict recorded in `docs/HANDOFF.md`: DG2's grep pattern
(`architect-loop`) collides with the repository's own name, and DG5's window
enumeration omitted the orchestrator's dispatch-bookkeeping commit
(e33f396, docs/HANDOFF.md only). Every intent check passed (DG1, DG3, DG4,
gates-integrity, diff-vs-intent). This file replaces ONLY the defective
mechanization; the fix contract and intent of v4-cleanup.md are unchanged
and incorporated by reference. The lane under judgment is commit 3db50d8 on
`slice/v4-cleanup`; no builder changes were requested or permitted between
the FAIL and this re-freeze.

Standing exemption (codified from VG9/XG6 precedent): orchestrator commits
that touch ONLY `docs/HANDOFF.md` and/or `docs/gates/` freeze files
(bookkeeping mandated by the loop procedure) are exempt from bounded-diff
enumerations; builder lane commits are not.

## Gates

**DG1' — Suite green both shells.** `uv run tests/validate_skills.py` exits
0 from Git Bash AND from PowerShell on `slice/v4-cleanup`.

**DG2' — Deletions complete and driver-unreferenced.**
`git ls-files bin tests/driver-canary.ps1` is EMPTY;
`grep -nE "architect-loop\.(ps1|sh)|bin/architect-loop|\.local/bin/architect-loop" install.sh install.ps1 README.md`
returns nothing (driver FILENAMES and install paths, not the repo name);
`grep -ni "sentinel" README.md` returns nothing; `bash -n install.sh` exits
0; PowerShell `Parser::ParseFile` on `install.ps1` reports 0 errors.

**DG3' — README per the v4-cleanup fix contract.** Unchanged from DG3:
one-session usage statement, Codex install path, desktop caveat (all
present); no driver or sentinel usage instructions.

**DG4' — DESIGN.md v4 evidence section per the v4-cleanup fix contract.**
Unchanged from DG4: all five evidence items present with sources/anchors.

**DG5' — Bounded lane diff.** Builder lane commit `3db50d8` changes exactly:
deletions `bin/architect-loop.ps1`, `bin/architect-loop.sh`,
`tests/driver-canary.ps1`; modifications `install.sh`, `install.ps1`,
`README.md`, `DESIGN.md`, `tests/validate_skills.py`,
`skills/architect/dispatch.md`; addition `docs/lanes/v4-cleanup-01.md`
(verify via `git show --name-status 3db50d8`). The window
`9c670b5..slice/v4-cleanup` may additionally contain only commits covered by
the standing exemption above.
`git diff 9c670b5..HEAD -- docs/prd/ docs/adr/ CONTEXT.md
skills/architect/SKILL.md skills/architect/loop.md
skills/architect/HANDOFF.template.md .claude/` is EMPTY.
