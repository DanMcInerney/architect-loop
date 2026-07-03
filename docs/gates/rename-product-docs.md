# Checks: rename-product-docs

Purpose: verify the domain-language rename in the product docs and diagram
HTML sources.
Spec (fix contract): `docs/spec/rename-domain-language.md`.
Files owned: `README.md`, `DESIGN.md`, `CONTEXT.md`,
`assets/architect-flow.html`, `assets/research-flow.html`.
PNG files are explicitly out of scope (spec A7 — orchestrator re-renders).

Executor: Git Bash preferred; PowerShell same-pattern substitution permitted
when recorded per check. Orchestrator bookkeeping commits are exempt from
touch-set checks.

## PD1 — retired terms absent from README and diagram HTML (word-boundary)

Command:
`git grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" -- README.md assets/architect-flow.html assets/research-flow.html`

PASS: no output.

## PD2 — DESIGN.md clean, with exactly one historical "grill" mention

Commands and PASS criteria:
- `git grep -inwE "gates?|lanes?|brain|brawn|cold|epic|dag" -- DESIGN.md` → no output
- `git grep -icw "grill" -- DESIGN.md` → `1`
- `git grep -iw "grill" -- DESIGN.md | grep -ci "in earlier runs"` → `1`
  (the single surviving mention is the historical naming note, e.g.
  "the stress-test pass (called the *grill* in earlier runs)")
- `git grep -inE "frontier" -- DESIGN.md | grep -ivE "frontier (model|codex|row|tier)|frontier-tier"` → no output
- `git grep -inE "stop rail|spec gate" -- DESIGN.md README.md` → no output

## PD3 — CONTEXT.md: new glossary above, retired terms below

Commands and PASS criteria:
- The glossary body ABOVE the retired-terms heading contains no retired
  vocabulary:
  `sed '/## Retired terms/,$d' CONTEXT.md | grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag|frontier"` → no output
- The retired-terms section documents every rename (one grep per term, all
  must match below the heading):
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw gate` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw dag` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw cold` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw epic` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw brain` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw brawn` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw lane` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw grill` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ciw frontier` → 1+
  `sed -n '/## Retired terms/,$p' CONTEXT.md | grep -ci "stop rail"` → 1+

## PD4 — new vocabulary present

Commands and PASS criteria:
- `git grep -cliE "tracking issue" -- README.md DESIGN.md CONTEXT.md` → lists all 3 files
- `git grep -cE "^orchestrator = " -- README.md` → `1` or more (config example)
- `git grep -cE "^builders = " -- README.md` → `1` or more
- `grep -ci "ORCHESTRATOR" assets/architect-flow.html` → `1` or more
- `grep -ci "BUILDERS" assets/architect-flow.html` → `1` or more
- `git grep -clie "frozen checks\|acceptance checks" -- README.md DESIGN.md` → lists both files

## PD5 — README/DESIGN local links resolve

Composite: covered by the orchestrator's post-merge validator run
(`check_local_links`); the job must not introduce links to files that do not
exist on this branch.
