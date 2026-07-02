# Gates — slice `v3-loop-docs`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

Parent: `v3-loop` (C1–C4 frozen and binding). v3 core merged to main
2026-07-02 with G7–G11 PASS. This slice fixes the three doc-level defects the
live canaries surfaced. Doc text only — no driver, test, or gate changes.

## Defects in scope (all observed live 2026-07-02, claude 2.1.198, this machine)

- **D6** — `skills/architect/dispatch.md` Claude Code backend template omits
  `--verbose`. Live behavior: `claude -p --output-format stream-json` errors
  immediately with "When using --print, --output-format=stream-json requires
  --verbose". The template as written cannot start a lane.
- **D7** — Headless `claude -p` in an untrusted workspace IGNORES the repo
  `.claude/settings.json` allowlist ("Ignoring N permissions.allow entries …
  this workspace has not been trusted"), so under `--permission-mode dontAsk`
  every non-flag-allowed tool call is denied and a loop brain cannot even
  update the handoff. `loop.md`'s one-time setup checklist has no
  workspace-trust step. Remedies observed: one interactive session accepting
  the trust dialog, or `projects["<path>"].hasTrustDialogAccepted: true` in
  `~/.claude.json` (named by the error message itself).
- **D8** — No lane-identity/self-stream rule for Claude-backend lanes whose
  stream-json is redirected to a file inside the workspace. Live failure: a
  lane found its own event stream + the architect's "lane 01 in flight"
  sentinel, inferred a duplicate worker, and exited with zero artifacts.
  Second live finding to fold into the same fix: PowerShell 5.1 `>` /
  `Tee-Object` redirection writes UTF-16, so byte-oriented `grep` on event
  files silently misses (liveness/rescue tooling must read encoding-aware).

## Declared timeout ceilings (graduated policy, PRD §4.4)

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| `bash -n bin/architect-loop.sh` | 60s |
| git commands | 120s |
| anything not declared above | 600s (default) |

On timeout: record it; one retry with a doubled ceiling ONLY if output showed
forward progress; else report as a stall. Never blind retry loops.

## Gates (architect-run at judgment unless noted)

**HG1 — D6 fixed.** The Claude Code backend template in
`skills/architect/dispatch.md` contains `--output-format stream-json
--verbose` (architect reads the row; `grep -n -- '--verbose'
skills/architect/dispatch.md` non-empty inside the backend table/templates).

**HG2 — D7 fixed.** `loop.md`'s one-time setup checklist gains a
workspace-trust item that (a) states the failure mode verbatim-in-substance
(untrusted → allowlist ignored → dontAsk denies), (b) names BOTH remedies:
one interactive session accepting the trust dialog, and the
`hasTrustDialogAccepted` key in `~/.claude.json`. Architect reads it.

**HG3 — D8 fixed.** `skills/architect/dispatch.md` gains, near the Builder
backends section: (a) a rule that a Claude-backend lane block MUST name the
lane's own event-stream file as its own output and state it is the only
builder when true — citing the live 2026-07-02 failure; (b) a Windows note
that PowerShell 5.1 redirection produces UTF-16 event files and reads must be
encoding-aware. Architect reads it.

**HG4 — Evidence lands in DESIGN.md.** The failure-mode table (or adjacent
section) gains one row/entry for builder self-misidentification (lane reads
its own stream, aborts as duplicate) with the 2026-07-02 canary as evidence,
per the standing "no feature ships without its evidence recorded" rule.

**HG5 — No regressions, bounded diff.**
(a) `uv run tests/validate_skills.py` exits 0 from Git Bash AND PowerShell;
(b) `git diff <this-freeze-commit>..HEAD -- bin/ tests/` is EMPTY;
(c) committed changes are exactly: `skills/architect/dispatch.md`,
    `skills/architect/loop.md`, `DESIGN.md`,
    `docs/lanes/v3-loop-docs-01.md` (new);
(d) net addition across the three edited files ≤ 45 lines;
(e) `git diff` on `docs/gates/` clean.
