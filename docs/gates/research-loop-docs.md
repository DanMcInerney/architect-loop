# Gates: research-loop-docs (frozen before dispatch)

Purpose: the dedicated docs lane consuming the `research-loop` docs-debt row
— README's `/architect-research` section catches up to the shipped A1-A4
mechanics + config parity (Q1), and DESIGN.md gains §11 recording the r2
evidence base, the 2,500-token measurement rationale, the grill's third
catch, defect D12, the composite-judgment precedent, and the slice SHAs
(Q2). Spec: `docs/spec/research-loop-docs.md`. This paragraph, that spec
pointer, and the gates below are the judge's ENTIRE intent context.

Standing exemption: commits by the orchestrator that touch ONLY
`docs/HANDOFF.md` (dispatch/judgment bookkeeping) are procedure-mandated
and do not violate QG4/QG5.

Builder note: quoted gate strings must appear with ASCII hyphens/spaces as
written. Editing this file is an automatic slice FAIL.

All commands run from Git Bash at the repo root
(`C:\Users\danhm\tools\architect-loop`; never from the nested repo under
`.architect/research`). Greps target explicit files. Ceilings: validator
120s per shell; greps 30s. `<freeze-sha>` = the freeze commit SHA passed in
the judge dispatch block (the commit that introduced this file).

## QG1 — validator green in both shells

- `uv run tests/validate_skills.py` exits 0 from Git Bash.
- From Git Bash (single quotes load-bearing):
  `powershell -NoProfile -ExecutionPolicy Bypass -Command 'uv run tests/validate_skills.py; exit $LASTEXITCODE'` exits 0.

## QG2 — README section (Q1)

- `grep -n "research handoff" README.md` non-empty.
- `grep -n "same brain/brawn config" README.md` non-empty.
- Read check: the `/architect-research` section (prose, plain-English voice,
  image and heading kept) conveys tool-call budgets, compact cited findings
  around 2,500 tokens with a numbered source list per lane, a skeleton
  draft whose gaps steer the follow-up round, and resuming from the
  committed report's open questions; no other README section restructured.

## QG3 — DESIGN.md §11 (Q2)

- `grep -n "## 11." DESIGN.md` non-empty.
- `grep -n "D12" DESIGN.md` non-empty.
- `grep -n "e39d0f4" DESIGN.md` non-empty.
- `grep -n "agent-pipeline-patterns" DESIGN.md` non-empty.
- Read check: §11 covers (a)-(e) from spec Q2 — evidence report + commit,
  2,500-token measurement rationale, grill third catch (2 blocking
  defects), D12 description + composite-judgment precedent (codex judge +
  headless claude -p + Win32 error 5 limitation), and freeze/lane/merge
  SHAs 1b2fd90 / 3f46f09 / e39d0f4; §§1-10 untouched.

## QG4 — touch set

- `git diff <freeze-sha>..HEAD --name-only` = exactly these paths and no
  others: `README.md`, `DESIGN.md`,
  `docs/lanes/research-loop-docs-01.md` (the lane report), and at most
  `docs/HANDOFF.md` (orchestrator bookkeeping per the standing exemption).
- `git diff <freeze-sha>..HEAD -- docs/gates/` is empty.

## QG5 — size discipline

- `git diff <freeze-sha>..HEAD --shortstat -- README.md DESIGN.md` reports
  total insertions+deletions <= 200.

## Merge rule

Merge to main only if QG1-QG5 all PASS and gates integrity holds. FAIL on
any gate = no merge; re-spec or KILL per the loop.
