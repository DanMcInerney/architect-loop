# Spec: rename the domain language

One mechanical, repo-wide vocabulary change. Jargon that only means something
after reading the docs (DAG, gate, cold, epic, brain/brawn, lane, grill,
frontier, stop rail) is replaced with terms a first-time reader already knows.
No behavior changes; no mechanism is added or removed.

## Goal

Every live file in the repo uses the new vocabulary below, consistently, and
`CONTEXT.md` documents the old terms as retired. The validator enforces the
new contracts and passes green.

## The rename table (domain language)

| Old term | New term | Notes |
|---|---|---|
| brain (role) | **orchestrator** | "orchestrator-tier" replaces "brain-tier" |
| brawn (role) | **builders** / a builder | |
| `brain =` / `brawn =` config keys | **`orchestrator =`** / **`builders =`** | no aliases; old keys hit the existing unknown-key warning |
| gate / gate file | **check** / check file | "frozen checks", "acceptance checks" |
| `docs/gates/` | **`docs/checks/`** | future runs; see A2 |
| spec gate | **spec approval** | the word "gate" disappears entirely |
| cold (agent) | **fresh** | judge may also be described as "independent" |
| epic (issue) | **tracking issue** | |
| issue DAG | **the plan** / issues linked with blocked-by | "DAG" retired as a noun |
| unblocked frontier | **ready issues** | "frontier" retired |
| lane / lane report | **job** / job report | build loop |
| `docs/lanes/` | **`docs/jobs/`** | future runs; see A2 |
| rulings file path | `docs/jobs/<issue-slug>-rulings.md` | |
| grill | **stress-test** | "one fresh stress-test pass attacks the whole plan" |
| stop rails | **hard stops** | |
| `docs/STOP` (prose) | the **kill switch** | filename unchanged |
| research lane | **researcher** | research skill |
| `skills/architect-research/lanes.md` | **`tactics.md`** | file renamed; validator + references updated |

**Unchanged on purpose:** orchestrator (already used), judge, monitor, scout,
canary, freeze/frozen, worktree, respawn, dispatch, wave, factory, spec,
digest, PHASE 0, tracking-issue digest flow, model alias names
(`codex/best`, `claude/best`, `codex/tier-down`, `claude/tier-down`).

## Non-goals

- No behavior, procedure, or mechanism changes — text only (plus one file
  rename and validator string updates).
- No rewriting of historical artifacts: `docs/spec/`, `docs/research/`,
  `docs/solutions/`, `docs/adr/`, git history, closed issues, and quoted
  material keep their original wording.
- No README/DESIGN content restructuring beyond term substitution and the
  small phrasing changes it forces.
- No PNG editing by builders (see A7).

## Scope: live files

| Set | Files |
|---|---|
| Build-loop skill | `skills/architect/SKILL.md`, `loop.md`, `dispatch.md`, `research.md` |
| Research skill | `skills/architect-research/SKILL.md`, `lanes.md` → `tactics.md` |
| Agent definitions | `.claude/agents/architect-builder.md`, `architect-judge.md`, `architect-monitor.md` |
| Enforcement | `tests/validate_skills.py`, `.gitignore`, `install.sh`, `install.ps1` |
| Product docs | `README.md`, `DESIGN.md`, `CONTEXT.md`, `assets/architect-flow.html`, `assets/research-flow.html` |

## Interface contract (shared strings — all issues implement exactly these)

Consumers: every issue below. Producer: this spec.

- Config grammar: `orchestrator = <cli>/<model-spec>[:<effort>]`,
  `builders = <cli>/<model-spec>[:<effort>]`, dispatch rules unchanged:
  `when <task class> -> <cli>/<model-spec>[:<effort>] # why`.
- Validator regex: `^(orchestrator|builders)\s*=\s*(claude|codex)/...` replaces
  the `(brain|brawn)` alternation.
- Judge template visible strings: `Frozen check file path:` replaces
  `Frozen gate file path:`; `Per check:` replaces `Per gate:`;
  `Checks integrity:` replaces `Gates integrity:`. HTML comment markers
  (`architect-judge-template`, `architect-codex-judge-template`,
  `architect-grill-template`) keep their names EXCEPT
  `architect-grill-template` → `architect-stress-test-template`.
- Section headings renamed: dispatch.md `## Grill delegation template` →
  `## Stress-test delegation template`; loop.md/SKILL.md pointer text updated
  to match. All other section headings unchanged.
- Paths in prose: `docs/checks/<issue-slug>.md`, `docs/jobs/<issue-slug>-01.md`,
  `docs/jobs/<issue-slug>-rulings.md`.
- `.gitignore`: add `!/docs/checks/` and `!/docs/jobs/`; KEEP `!/docs/gates/`
  and `!/docs/lanes/` (historical branches and this run's own artifacts).

## Assumptions (veto or edit at approval)

- **A1.** "epic" → "tracking issue"; "digest" stays "digest".
- **A2.** The `docs/checks/` and `docs/jobs/` paths govern *future* runs.
  This run's own artifacts follow the currently installed skill:
  its check files freeze under `docs/gates/`, job reports under `docs/lanes/`.
- **A3.** Historical references inside DESIGN.md's evidence section stay
  truthful: first mention reads "the stress-test pass (called the *grill* in
  earlier runs)"; quoted research text and D-numbering notes are untouched.
- **A4.** `CONTEXT.md`'s "Retired terms" section absorbs: gate, DAG, cold,
  epic, brain, brawn, lane, grill, frontier, stop rail — one line each with
  its replacement. CONTEXT.md is therefore *exempt* from old-term sweep checks.
- **A5.** Old config keys are not aliased (existing unknown-key warning is the
  migration path). No config files exist on this machine.
- **A6.** Installers are path-based and likely need no term changes; the
  enforcement issue verifies and touches them only if they reference renamed
  files.
- **A7.** `assets/*.html` text is updated by the docs issue; the PNGs are
  re-rendered by the orchestrator after merge (browse tooling); if that fails
  it is recorded in the digest as follow-up work, not silently skipped.
- **A8.** Grep-based acceptance checks use word boundaries and case
  sensitivity chosen to avoid substring traps ("delegate", "aggregated",
  "Plane") and exempt CONTEXT.md's retired-terms section and A3 historical
  mentions in DESIGN.md.

## Validation strategy

Per issue: word-boundary greps proving (a) zero occurrences of the issue's
old terms in its owned files (minus recorded exemptions) and (b) presence of
the new contract strings. Composite, at integration:
`uv run --no-project python tests/validate_skills.py` green, plus one
repo-wide sweep of all old terms over live files (historical dirs and
CONTEXT.md retired section excluded).

## Preflight evidence

- `gh` 2.96.0 ≥ 2.94.0; `gh auth status` ✓ (DanMcInerney, keyring), remote =
  github.com/DanMcInerney/architect-loop.
- Builder backend: Codex CLI 0.139.0 on PATH; canary result recorded on the
  tracking issue at decomposition.
- PR #29 merged first (human ruling); base = main @ 1db1ba9.

## Open human decisions

None beyond the assumptions above — A1–A8 apply unless vetoed at approval.
