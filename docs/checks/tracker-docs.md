# Checks: tracker-docs

Purpose: verify the docs closure for markdown tracker mode.
Spec (fix contract): `docs/spec/tracker-markdown.md`.
Files owned: `README.md`, `DESIGN.md`, `CONTEXT.md`.

Executor: PowerShell primary. Orchestrator bookkeeping commits exempt.

## TC1 — README

- `git grep -cE "^tracker = markdown" -- README.md` → count ≥ 1 (the config line shown)
- `git grep -ci "gitlab" -- README.md` → count ≥ 1
- `git grep -c "docs/issues/" -- README.md` → count ≥ 1
- Preconditions text is per-mode (markdown mode: no gh, remote optional) —
  quote the sentences.
- The what-doesn't-change sentence (rules/judges/checks/status tree
  identical) — quote it.

## TC2 — DESIGN

- `git grep -c "tracker-markdown" -- DESIGN.md` → count ≥ 1 (spec cited)
- `git grep -ci "line protocol\|TSV" -- DESIGN.md` → count ≥ 1
- The decision entry cites the community request and the
  single-implementation lesson — quote the entry.

## TC3 — CONTEXT

- Tracker entry is per-mode — quote it.
- `git grep -cE "tracker =" -- CONTEXT.md` → count ≥ 1
- Glossary above retired-terms stays clean of retired vocabulary
  (word-boundary sweep) → no output.

## TC4 — link integrity self-check

`git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md` — `Test-Path`
each target, paste results. Full validator at composite.
