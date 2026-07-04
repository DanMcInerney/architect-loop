# Checks: tracker-status

Purpose: verify the markdown backend for the status tree.
Spec (fix contract): `docs/spec/tracker-markdown.md` — TSV emission and
issue-format rules are pinned there.
Files owned: `skills/architect/status.ps1`, `skills/architect/status.sh`.

Executor: PowerShell primary. Markdown mode is FULLY testable in this
sandbox (files only). The sh twin cannot execute here — static checks for
sh; the orchestrator runs the sh functional pass at composite. Fixtures
under `.architect/tmp/tmfix/`. Orchestrator bookkeeping commits exempt.

## TS1 — fixture layout (exact)

Build fixture root `.architect/tmp/tmfix/root1/` containing:
```
root1/.architect/config                      (single line: tracker = markdown)
root1/docs/issues/003-old-run.md             (state: OPEN, parent: none — DECOY candidate: number 3, parent of nothing... give it one child 004 with state CLOSED)
root1/docs/issues/004-old-child.md           (state: CLOSED, parent: 3)
root1/docs/issues/007-current-run.md         (state: OPEN, parent: none)
root1/docs/issues/008-done-job.md            (state: CLOSED, parent: 7, title: done job)
root1/docs/issues/009-blocked-job.md         (state: OPEN, parent: 7, blocked-by: 8, 10, title: blocked job)
root1/docs/issues/010-ready-job.md           (state: OPEN, parent: 7, blocked-by: none, title: ready job)
root1/docs/spec/demo.md                      (any content)
```
Every issue file uses the spec's exact frontmatter block. Note: issue 9's
blockers are 8 (CLOSED) and 10 (OPEN) — the open-blocker filter must keep
only 10.

## TS2 — functional: markdown tracker render (ps1)

Run status.ps1 with `-RepoRoot .architect/tmp/tmfix/root1`.
PASS (verbatim output pasted): exit 0; tracker header shows `#7` (highest
OPEN parent-referenced candidate — NOT the decoy 3); a MERGED-glyph row for
#8; a QUEUED-glyph row for #9 listing blocker `10` ONLY (not 8); a
READY-glyph row for #10; no out-of-contract glyphs; `branch: unknown`
tolerated.

## TS3 — functional: empty and no-candidate markdown states

- `root2/`: `.architect/config` with tracker = markdown, EMPTY `docs/issues/`
  dir, no artifacts → output contains `NO ACTIVE FACTORY RUN`, exit 0.
- `root3/`: same config, issues 007/008 present but BOTH `state: CLOSED`,
  NO `.architect/wt/` artifacts, no other files → exact expectation per the
  gh-mode semantics table (tracker reachable, no open candidate, no
  artifacts): output contains `NO ACTIVE FACTORY RUN`, exit 0.

## TS4 — gh-mode regression

- With NO `.architect/config` (or `tracker = github`), the gh path runs:
  re-run the existing STATUS_GH_STUB fixture (stub TSV → rendered rows) and
  paste output — identical behavior to pre-change.

## TS5 — piped ESC + parse + budgets

- Piped ps1 markdown-mode output contains zero ESC bytes (existing byte
  check form) → `False`.
- ps1 parse check (in-session ParseFile form) → OK.
- Non-blank line counts: each script ≤ 150.

## TS6 — sh static parity

- status.sh contains the mode read (`tracker`), the frontmatter keys, and
  the unit-separator TSV pattern — quote the relevant lines file:line.
- `bash -n` equivalent is composite (orchestrator); record that.
