# Gates — slice `v3-loop-fixes`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

Parent slice: `v3-loop` (contracts C1–C4 in `docs/gates/v3-loop.md` remain
frozen and binding; this slice changes NO contract). This slice fixes three
defects found by the 2026-07-02 judgment session's driver canaries, plus one
doc omission, and commits the canary harness so the measurements are
repeatable.

## Defects in scope (verbatim evidence in docs/HANDOFF.md raw results)

- **D1** — `tests/validate_skills.py` `check_drivers()` passes the sh driver's
  absolute Windows path (backslashes) to the first `bash` on PATH with no
  `cwd`. From PowerShell, `shutil.which('bash')` resolves WSL's
  `C:\WINDOWS\system32\bash.exe` → `/bin/bash: C:Usersdanhm...: No such file
  or directory` → suite exits 1 on a healthy tree. The sibling PowerShell
  check already does it right (relative path + `cwd=ROOT`).
- **D2** — `bin/architect-loop.ps1` degradation warning names the WRONG
  requested CLI: `Get-TierDown` (via `Resolve-Role`/`Split-Role`) clobbers
  `$script:RoleCli` before the warning string interpolates it. Observed:
  config `brawn = codex/best` with codex absent produced
  `brawn CLI 'claude' not on PATH; falling back to claude/sonnet:high`.
  PRD §5.6(b) requires requested-vs-substituted.
- **D3** — `bin/architect-loop.ps1` `Invoke-Brain` leaks the child's
  tee'd stdout into the function's output stream, so `$status` at the call
  site is an ARRAY (output lines + exit code), not a number. Consequences,
  both observed live: (a) every audit line's `exit=` field contains child
  stdout; (b) `if ($status -ne 0) { $nonzero++ }` is truthy on every
  iteration with output, so a HEALTHY loop stops at iteration 5 with
  `5 consecutive nonzero exits` — C4 promises `--max-iters` default 50.
  The bash driver is clean (PIPESTATUS[0]); fix the ps1 driver only.
- **D4** — `skills/architect/loop.md` harness invocation table omits
  `--effort` from the Claude-brain command while the driver passes it
  (flag verified real on claude 2.1.198).

## Declared timeout ceilings (graduated policy, PRD §4.4)

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache) | 120s |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tests/driver-canary.ps1` | 300s |
| `bash -n bin/architect-loop.sh` | 60s |
| PowerShell Parser::ParseFile check (v3-loop G3 command) | 120s |
| git commands | 120s |
| anything not declared above | 600s (default) |

On timeout: record it; one retry with a doubled ceiling ONLY if output showed
forward progress; else report as a stall. Never blind retry loops.

## Gates (architect-run at judgment unless noted)

**FG1 — Suite green from both shells.** `uv run tests/validate_skills.py`
exits 0 on this machine when invoked from Git Bash AND from PowerShell (where
PATH resolves WSL bash first). A genuinely broken sh driver must still FAIL
the suite where a working bash is used; D1's fix may skip-with-note only when
the resolved bash cannot execute repo scripts at all (e.g. System32 WSL
without a distro), never on real syntax errors.

**FG2 — Driver canary harness.**
`powershell -NoProfile -ExecutionPolicy Bypass -File tests/driver-canary.ps1`
exits 0. The harness must build a throwaway toy repo + stub `claude` on a
controlled PATH entirely under `.architect/tmp/`, run the REAL
`bin/architect-loop.ps1`, and assert at minimum:
(a) a healthy run with changing sentinels reaches `--max-iters 8`
    (`STOP: --max-iters 8 reached`) — no false breaker trip;
(b) every `loop.log` audit line's `exit=` field is a bare integer;
(c) deleting the `LOOP:` line stops the driver with
    `missing or unparseable LOOP sentinel`;
(d) an untouched handoff stops it with `docs/HANDOFF.md untouched after
    iteration`;
(e) a frozen WAIT sentinel with no event growth stops it with
    `3 consecutive no-progress iterations`;
(f) config `brawn = codex/best` with codex absent from PATH warns naming
    BOTH `codex` (requested) and the substituted tier-down, and the audit
    line shows the substituted brawn;
(g) five consecutive nonzero-exit iterations stop it with
    `5 consecutive nonzero exits`.

**FG3 — Parse regressions.** `bash -n bin/architect-loop.sh` exits 0 (the
sh driver must be byte-identical to the freeze commit anyway) and the v3-loop
G3 Parser::ParseFile command on `bin/architect-loop.ps1` exits 0.

**FG4 — Bounded diff.** Only these files change:
`bin/architect-loop.ps1`, `tests/validate_skills.py`,
`tests/driver-canary.ps1` (new), `skills/architect/loop.md` (≤ 3 net lines),
`docs/lanes/v3-loop-fixes-01.md` (new). `git diff` on `docs/gates/` clean.

Merge of `slice/v3-loop` → main still requires the parent gate file's
G7–G11 canaries, which a fresh architect session runs against the FIXED
driver after this slice integrates. G1–G6 verdicts recorded 2026-07-02 stand.
