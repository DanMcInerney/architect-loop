# Gates — slice `v3-loop-eol`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

Parent slice: `v3-loop` (contracts C1–C4 in `docs/gates/v3-loop.md` frozen and
binding). Grandparent fix slice `v3-loop-fixes` judged 2026-07-02: FG2, FG3,
FG4 PASS; FG1 FAIL with defect D5 below. This slice fixes D5 only.

## Defect in scope

- **D5** — The repo has no `.gitattributes`, so on a Windows clone with
  `core.autocrlf=true` (this machine) the sh driver is checked out with CRLF
  line endings (`git ls-files --eol bin/architect-loop.sh` → `i/lf w/crlf
  attr/` empty). `tests/validate_skills.py`'s `choose_bash()` from PowerShell
  resolves `C:\Users\...\AppData\Local\Microsoft\WindowsApps\bash.exe` (WSL,
  strict LF — the System32 heuristic does not match it), the `test -r` probe
  passes, and `bash -n` correctly fails on the mangled file:

  ```
  bin/architect-loop.sh: line 10: syntax error near unexpected token `$'{\r''
  ```

  → suite exit 1 from PowerShell on a healthy tree, which failed frozen gate
  FG1. Git Bash passes only because MSYS bash tolerates CRLF. The sh driver's
  *content* (index blob) is correct; the defect is checkout normalization.

## Declared timeout ceilings (graduated policy, PRD §4.4)

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tests/driver-canary.ps1` | 300s |
| `bash -n bin/architect-loop.sh` | 60s |
| PowerShell Parser::ParseFile check (v3-loop G3 command) | 120s |
| git commands | 120s |
| anything not declared above | 600s (default) |

On timeout: record it; one retry with a doubled ceiling ONLY if output showed
forward progress; else report as a stall. Never blind retry loops.

## Gates (architect-run at judgment unless noted)

**EG1 — FG1 re-run, both shells green.** `uv run tests/validate_skills.py`
exits 0 on this machine from Git Bash AND from PowerShell. The FG1 skip
clause carries over unchanged: skip-with-note only when the resolved bash
cannot execute repo scripts at all, never on real syntax errors.

**EG2 — Checkout normalization pinned.** `.gitattributes` exists at repo root
containing a rule pinning `*.sh` to `text eol=lf`.
`git ls-files --eol -- '*.sh'` shows `i/lf` and `w/lf` and a non-empty
`attr/` column with `eol=lf` for `bin/architect-loop.sh` and `install.sh`.

**EG3 — No regressions.**
(a) `powershell -NoProfile -ExecutionPolicy Bypass -File tests/driver-canary.ps1`
    exits 0;
(b) `bash -n bin/architect-loop.sh` exits 0;
(c) the v3-loop G3 Parser::ParseFile command on `bin/architect-loop.ps1`
    exits 0;
(d) `git diff <this-freeze-commit>..HEAD -- bin/ tests/ skills/` is EMPTY —
    working-tree line-ending refresh of `*.sh` must produce no committed
    content change (the index is already LF).

**EG4 — Bounded diff.** Committed changes are exactly:
`.gitattributes` (new), `docs/lanes/v3-loop-eol-01.md` (new). Working-tree
line-ending rewrite of `*.sh` files to LF is permitted (and required for EG2's
`w/lf`) but must leave `git status --porcelain` clean for those files.
`git diff` on `docs/gates/` clean.

Merge of `slice/v3-loop` → main still requires the parent gate file's G7–G11
canaries, run by a fresh architect session against this tree after this slice
integrates. G1–G6 and FG2–FG4 verdicts stand.
