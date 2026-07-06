# Job report: skill-library/s5-tdd-agents (job skill-library/s5-01, shape: ship)

Run: `skill-library`. Issue: #108. Spec: `docs/spec/skill-library.md`.
Check (frozen, read-only): `docs/checks/skill-library/s5-tdd-agents.md`
(freeze SHA `3f56e7c`).

## Environment note (not a spec disagreement)

This job's worktree was created from `factory/skill-library` at commit
`c9c1f95` (run intake). The freeze commit `3f56e7c` (and two commits ahead
of it: `1bb9cb3`, `7d800b4`) sit later on that branch and are not in this
worktree's history, so `docs/checks/skill-library/s5-tdd-agents.md` is not
physically present on disk here:

```
$ git branch --contains 3f56e7c
+ factory/skill-library
```

Its content was read via `git show 3f56e7c:docs/checks/skill-library/s5-tdd-agents.md`
(quoted in the PHASE 0 comment on issue #108) instead of `Read`ing a
worktree file. None of the check's RUN items reference the check file's own
path — they test `skills/tdd/*` and the two agent defs — so every RUN item
below was still executable and graded exactly as frozen. I did not create or
modify anything under `docs/checks/`.

## PHASE 0

Posted to issue #108 before any file was touched:
https://github.com/DanMcInerney/architect-loop/issues/108#issuecomment-4888434309

Verified before planning:
- `raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/tdd/{SKILL.md,tests.md,mocking.md}` — fetched live, HTTP 200, 36/77/59 lines respectively.
- License: `gh api repos/mattpocock/skills` → `"license":{"key":"mit",...}` (independent confirmation, not just the spec's citation).
- Read both existing agent defs in full before editing.
- Confirmed `skills/codebase-design/` and `skills/tdd/` absent from this worktree pre-job (parallel s1 job owns codebase-design; not read or depended on).

No disagreements with the spec were found; only the environment gap above.

## Files changed (within BOUNDARIES)

- `skills/tdd/SKILL.md` (new, 60 lines)
- `skills/tdd/tests.md` (new, 88 lines)
- `skills/tdd/mocking.md` (new, 58 lines)
- `.claude/agents/architect-builder.md` (modified: +3 lines — 1 frontmatter field, 1 body bullet + wrap)
- `.claude/agents/architect-judge.md` (modified: +1 line — 1 frontmatter field)

```
$ git status --short
 M .claude/agents/architect-builder.md
 M .claude/agents/architect-judge.md
?? skills/tdd/

$ git diff --stat .claude/agents/architect-builder.md .claude/agents/architect-judge.md
 .claude/agents/architect-builder.md | 3 +++
 .claude/agents/architect-judge.md   | 1 +
 2 files changed, 4 insertions(+)
```

Builder frontmatter now includes `skills: [tdd, codebase-design]`; all
existing `tools:`/`disallowedTools:`/`model:`/`isolation:`/`background:`
fields and every existing operating rule are unchanged. Added one new
body bullet as the first item in Operating rules:

```
- FIRST ACTION: if the tdd skill content is not already in context, Read
  `skills/tdd/SKILL.md` and `skills/codebase-design/SKILL.md` before planning.
```

Judge frontmatter now includes `skills: [codebase-design]` only; no other
line in the judge def was touched.

## Frozen check RUN items — executed verbatim (Git Bash, worktree root)

| # | RUN command | Expected | Actual output | Exit |
|---|---|---|---|---|
| 1 | `test -f skills/tdd/SKILL.md -a -f skills/tdd/tests.md -a -f skills/tdd/mocking.md` | exit 0 | (silent) | 0 |
| 2 | `grep -F -q "name: tdd" skills/tdd/SKILL.md` | exit 0 | (silent) | 0 |
| 3 | `grep -F -q "Adapted from mattpocock/skills (MIT)" skills/tdd/SKILL.md` | exit 0 | (silent) | 0 |
| 4 | `bash -c 'for t in "red" "green" "seam" "tracer" "vertical"; do grep -qi "$t" skills/tdd/SKILL.md \|\| { echo "MISSING: $t"; exit 3; }; done; echo ALL_TERMS'` | exit 0, match `ALL_TERMS` | `ALL_TERMS` | 0 |
| 5 | `bash -c 'for f in skills/tdd/SKILL.md skills/tdd/tests.md skills/tdd/mocking.md; do test -f "$f" \|\| { echo "MISSING: $f"; exit 3; }; done; n=$(cat skills/tdd/SKILL.md skills/tdd/tests.md skills/tdd/mocking.md \| wc -l); test "$n" -le 220 && echo "LINES_OK $n"'` | exit 0, match `LINES_OK` | `LINES_OK 206` | 0 |
| 6 | `bash -c 'grep -q "skills:" .claude/agents/architect-builder.md && grep -q "tdd" .claude/agents/architect-builder.md && grep -q "codebase-design" .claude/agents/architect-builder.md && echo BUILDER_WIRED'` | exit 0, match `BUILDER_WIRED` | `BUILDER_WIRED` | 0 |
| 7 | `bash -c 'grep -q "skills:" .claude/agents/architect-judge.md && grep -q "codebase-design" .claude/agents/architect-judge.md && echo JUDGE_WIRED'` | exit 0, match `JUDGE_WIRED` | `JUDGE_WIRED` | 0 |
| 8 | `bash -c '! grep -Eiq "show your (reasoning\|thinking)\|explain your reasoning" skills/tdd/*.md && echo NO_ECHO'` | exit 0, match `NO_ECHO` | `NO_ECHO` | 0 |

Individual line counts confirmed separately:
```
$ wc -l skills/tdd/SKILL.md skills/tdd/tests.md skills/tdd/mocking.md
  60 skills/tdd/SKILL.md
  88 skills/tdd/tests.md
  58 skills/tdd/mocking.md
```
(≤60 / ≤90 / ≤70 per-file budgets, all met; combined 206 ≤ 220.)

All 8 RUN items: PASS (exit 0, all expected match strings present verbatim).

## Judge-only intent items — self-check against my own build (judge still owns the verdict)

- Seams pre-agreed via issue body/spec, not user interview: `skills/tdd/SKILL.md` § "Seams are pre-agreed, not interviewed" states this directly; frozen checks named read-only and explicitly distinguished from the builder's own tests in the same section and again in `tests.md` § "Factory seams".
- Never refactor while RED: `skills/tdd/SKILL.md` § "Rules of the loop" — "Never refactor while RED. Refactoring belongs to review, not the red -> green cycle."
- Mock at system boundaries only: `skills/tdd/mocking.md` § "When to Mock" — kept, with "Don't mock: Your own modules; Internal collaborators; Anything the codebase itself controls."
- Anthropic evidence-grounding steering: `skills/tdd/SKILL.md` § "Report only what you proved" — "report only what a tool result from this session actually shows... not a claim of passing without the run behind it."
- Agent-def edits additive only: diff stat above shows +3/+1 lines only, no deletions, in either agent def; confirmed by reading the full builder def post-edit (quoted above) — every original rule, including worktree isolation, no-commit, and the `docs/checks/` read-only rule, is present unchanged.
- Original wording beyond the adapted MIT source: `SKILL.md`'s "Seams are pre-agreed, not interviewed", "Frozen checks under docs/checks/ are read-only grading...", and "Report only what you proved" sections are original factory-specific prose, not present in the Pocock source (verified by diffing against the fetched source text above); `tests.md`'s "Factory seams" closing section is likewise original. Pocock wording that was kept (anti-pattern descriptions, mocking boundary list) is the material the issue explicitly said to keep.
- Glossary terms: used "module" (not component/service), "interface"/"seam" (not boundary/API — the one "system boundaries" occurrence is the issue's own explicitly-kept Pocock phrase for mock scope, and "external third-party systems" replaces the source's "External APIs" to avoid any API/interface collision), "issue" (not task/ticket), "frozen check" (not test file), "builder" throughout.

## Boundary compliance

- No file outside `skills/tdd/**`, `.claude/agents/architect-builder.md`, `.claude/agents/architect-judge.md`, or this report was created or modified.
- `docs/checks/**` was not touched (read, never written).
- No commit was made; `git status --short` above shows only working-tree changes.

## Mirror

PHASE 0 comment posted successfully via `gh issue comment 108`. Posting this
STATUS as an issue comment now (see below); if that call fails the exact
error will be recorded and `MIRROR: ORCHESTRATOR` noted instead.

STATUS: COMPLETE
