# Checks: status-docs

Purpose: verify the docs closure for the status tree.
Spec (fix contract): `docs/spec/status-tree.md` A5; evidence
`docs/research/status-display-evidence.md`.
Files owned: `README.md`, `CONTEXT.md`, `DESIGN.md`.

Executor: PowerShell primary; native `git.exe` fine. Orchestrator
bookkeeping commits exempt from touch-set checks.

## SD1 — README

- `git grep -ci "how's it going\|how it's going" -- README.md` → count ≥ 1
- `git grep -ci "status.ps1" -- README.md` → count ≥ 1
- README contains a fenced sample tree using at least three of the six
  glyphs — quote the block.

## SD2 — CONTEXT

- `git grep -ci "status tree" -- CONTEXT.md` → count ≥ 1
- The entry states it is a read-only render (quote the line); the glossary
  above the retired-terms section stays clean:
  PowerShell equivalent of `sed '/## Retired terms/,$d' CONTEXT.md` piped to
  word-boundary grep for `gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag` → no output.

## SD3 — DESIGN

- `git grep -c "status-display-evidence" -- DESIGN.md` → count ≥ 1
- `git grep -ci "status tree" -- DESIGN.md` → count ≥ 1
- `git grep -ciE "lazyagent|agent view" -- DESIGN.md` → count ≥ 1
- The entry notes live-watch was descoped by human ruling — quote it.

## SD4 — link integrity self-check

`git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md` — verify each
listed target exists with `Test-Path`; paste results. (Full validator runs
at composite.)
