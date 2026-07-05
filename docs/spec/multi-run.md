# Spec: multi-run — multiple isolated architect loops per repo

Run slug: `multi-run`. Tracker mode: github (preflight evidence below).

## Problem

The loop re-discovers its run by a global tracker scan instead of pinning it.
Evidence:

- `skills/architect/status.ps1:88` and `status.sh:56`: the pinned jq selects
  the highest-numbered OPEN issue that is a parent of at least one issue as
  TRACK. Any newer run's tracking issue, or any third party using GitHub
  native sub-issues in the repo, silently retargets every loop.
- `skills/architect/tracker.md:34`: markdown mode codifies the same
  highest-open-parent algorithm, and issue numbering is global
  ("max existing + 1") — a race across concurrent factory branches.
- Run artifacts share flat namespaces: `docs/checks/<slice>.md`,
  `docs/jobs/<issue-slug>-*.md`, `docs/issues/<NNN>-<slug>.md`. Two runs with
  colliding slugs overwrite each other.
- All run commits land through the orchestrator's checkout, so two live
  orchestrator sessions in one clone fight over the working tree.
- `docs/STOP` is the only stop; it kills every loop with no per-run stop.

## Goal

N architect runs coexist in one repo, each isolated: pinned run identity, no
global tracker scans, namespaced artifacts, one checkout per live run, per-run
stop, and immunity to third-party issues by construction.

## Non-goals

- No GitLab or other tracker adapters.
- No GitHub labels as run identity (git manifest + run marker instead).
- No backwards compatibility with the flat layout or the highest-open-parent
  scan (repo backcompat ban; loop-hardening, merged cc975d4).
- No changes to job-level (builder) worktree mechanics beyond branch naming.
- No cross-repo or multi-repo runs.

## Design

### D1. Run identity: pin, don't scan

- A run is named by a slug at intake. A committed **run manifest** at
  `docs/runs/<run>/manifest.md` pins the run: line-greppable frontmatter with
  exactly `run`, `tracking-issue`, `factory-branch`, `tracker`, `spec`,
  `state` (ACTIVE|FINISHED), `created` — same parse discipline as markdown
  issue frontmatter (`tracker.md`).
- The tracking issue body carries the machine-readable run marker
  `<!-- architect-run: <run> -->` and the manifest path. Every sub-issue the
  orchestrator creates carries the same marker. Pinning is bidirectional:
  manifest -> issue number; issue body -> run slug + branch.
- Creation order at intake end: create the tracking issue first, then write
  the manifest with its number.

### D2. Tracker selection rewrite

- `status.ps1` / `status.sh` take a run slug argument, resolve
  `docs/runs/<slug>/manifest.md` in the current checkout, and emit the same
  TSV protocol with TRACK = the pinned number. SUB rows are issues whose
  parent edge is the pinned number AND whose author is the authenticated
  account (`--json author`); github-mode selection never computes a max over
  the whole tracker. `NOOPENRUN` remains only for "pinned issue is closed or
  manifest missing".
- A foreign sub-issue attached under the run parent (wrong author or missing
  run marker) is never dispatched; it is escalated on the tracking-issue
  digest. NOTE: the word "sentinel" is validator-retired in skill text
  (`check_retired_loop_terms`); the domain term is "run marker".
- Grounding scope (SKILL.md step 0): read open issues of this run only —
  children of the pinned tracking issue plus the tracking issue itself. The
  wider tracker is explicitly out of scope for the loop.
- Markdown mode: identical pinning through the manifest; the
  highest-open-parent fallback text in `tracker.md` is deleted.

### D3. Namespaced artifacts

- `docs/checks/<run>/<slice>.md`, `docs/jobs/<run>/<issue-slug>-*.md`,
  `docs/issues/<run>/<NNN>-<slug>.md` (markdown-mode numbering local to the
  run, starting at 1). Spec stays at `docs/spec/<run>.md`; the manifest points
  to it.
- Hard Rule 2's freeze audit (`git diff <freeze-sha>..HEAD -- docs/checks/`)
  is unchanged — the path prefix still covers per-run subdirectories.
- Job branches become `job/<run>/<slice>-<NN>`; codex-backend job worktrees
  become `.architect/wt/<run>/<slice>-<NN>`.

### D4. One checkout per live run

- Each concurrently live run gets its own orchestrator checkout: a dedicated
  git worktree on its own `factory/<run>` branch (local convention
  `.architect/runs/<slug>`, machine-local, never committed). Never two
  orchestrator sessions in one checkout. A single-run repo may keep using the
  primary checkout unchanged.

### D5. Stop semantics

- `docs/STOP` stays the absolute kill-all. The stop check covers the run's
  own checkout and the primary checkout (resolved via
  `git rev-parse --git-common-dir`), so a human touching `docs/STOP` anywhere
  stops all runs.
- `docs/runs/<run>/STOP` stops exactly one run, checked the same way.

## Validation strategy

- `python tests/validate_skills.py` stays green; its `NOOPENRUN` fixture and
  any pinned-jq drift guards are updated to the pinned-selection form.
- New fixture test: two run manifests plus issue fixtures, and a foreign
  higher-numbered parent issue; each run's status emission returns its own
  pinned TRACK, and the foreign issue never appears.
- Grep guard: the global-max selection (`map(.number) | max`) is absent from
  both status scripts.
- Existing skill-text size guards hold (1100/500/5k-proxy/TOC/drift).
- Every script change ships as a `.ps1`/`.sh` pair (standing human ruling).

## Domain language

**run** (one architect loop instance), **run slug**, **run manifest** (the
committed pin), **pinned tracking issue**, **run marker** (the HTML comment),
**foreign issue** (any issue not created by the orchestrator for this run),
**run checkout** (the worktree a live run operates in).

## Rulings (human, in-session, 2026-07-05)

Intake questions were asked through the timed-ruling protocol; the human
answered in-session: "yes do your recommendations".

- Q1 concurrency: fully concurrent loops, one worktree per live run (D4).
- Q2 identity: git-committed run manifest + body run marker; no labels (D1).
- Q3 namespacing: per-run subdirectories (D3).
- Q4 stop: global `docs/STOP` stays absolute; per-run stop added (D5).

## Preflight evidence (2026-07-05)

gh 2.96.0 (>= 2.94.0); `gh auth status` logged in as DanMcInerney; origin =
https://github.com/DanMcInerney/architect-loop; no open issues; no run in
flight; no `docs/STOP`.

## Approval record

In-session approval, 2026-07-05: the repo owner replied `1` to the approval
options presented in-session, where option 1 was `APPROVE (recommended
default)`. Verbatim reply: "1". Timer killed before expiry; no auto-ruling.
