# DESIGN - Architect Loop Local-Scratch Fork

This fork keeps the upstream architect/builder separation but changes the
storage and planning contract for projects that do not want loop artifacts in
their repository history or PRs.

## Roles

| Role | Who | Owns |
|---|---|---|
| Architect | Claude Opus 4.8 in Claude Code | grilling, arbitration, gates, verification, patch-bundle handoff |
| Builder | GPT-5.5 via `codex exec` | implementation inside one declared lane |
| Researcher | GPT-5.5 via read-only `codex exec` | raw sourced findings |
| Memory | `.scratch` plus Git history | local loop state and source diffs |

## Core Invariants

1. **The architect does not write implementation code.** It writes specs,
   gates, prompts, verdicts, and local planning artifacts.
2. **All loop artifacts are ignored.** Specs, issue slices, gates, prompts,
   reports, run logs, handoffs, and worktrees live under `.scratch`.
3. **Git remains the code-diff authority.** Implementation changes are reviewed
   with `git diff`, `git status`, and `git ls-files`. SHA-256 checks only
   protect frozen local artifacts.
4. **Full-lane gates freeze before results exist.** `/architect` snapshots
   gates under `.scratch/architect-loop/state/<slice>/freeze/` and records a
   checksum before dispatch. `/architect-fast` deliberately substitutes a
   checksum-protected acceptance packet, builder-run tests, and one fresh
   closing review-and-fix.
5. **Builders do not normally grade their own work.** They report raw command
   output; the architect runs gates and reads the implementation diff. The
   fast lane's one fresh closing builder may review and fix the combined work,
   after which the architect reruns validation and inspects the final diff.
6. **Disagreement is mandatory.** Builders must challenge the spec before
   coding, citing real files.
7. **Every builder runs in a fresh worktree.** This applies even to one-lane
   slices, so generated state and source edits stay isolated.
8. **No publication side effects.** The skills do not create issues, branches,
   commits, PRs, or committed docs. They stop at local evidence and patch files.
9. **Only local planning files exist by default.** Specs and issue slices are
   `.scratch` files; there is no external issue tracker path in this fork.
10. **Grilling precedes slicing when scope is not already settled.** The
    architect asks one question at a time, inspects code when possible, updates
    glossary/ADRs only when warranted, then distills to local spec and issue slices.
11. **No builder fallback.** GPT-5.5 through Codex is required for builders and
    researchers. Missing Codex is a blocker, not a Claude-subagent fallback.

## Artifact Layout

```text
.scratch/architect-loop/planning/<feature-slug>/SPEC.md
.scratch/architect-loop/planning/<feature-slug>/issues/<NN>-<slug>.md

.scratch/architect-loop/state/<slice>/
  manifest.json
  spec.md
  gates.md
  freeze/gates.md
  freeze/gates.sha256
  dispatch/<lane>.prompt.md
  reports/<lane>.md
  runs/<lane>.jsonl
  runs/<lane>.stderr.log
  runs/<lane>.last.md
  checks/<lane>-checkrun.md
  judges/<lane>.md
  patches/<lane>.patch
  final.patch
  verdict.md

.scratch/architect-loop/worktrees/<slice>-<lane>/
.scratch/architect-loop/research/<topic>/
```

## Gate Integrity Vs Code Diff Review

The upstream design committed gate files and used `git diff` to detect
tampering. This fork cannot rely on committed gate artifacts because generated
loop files must not reach the deployment repository.

Replacement:

- Gate tamper detection: compare `.scratch` gate files against a frozen copy and
  checksum.
- Implementation review: keep using Git diffs from the recorded `base_sha`.

These are intentionally separate. A checksum answers whether the gate artifact
changed. It does not show implementation changes and must never be used as a
replacement for source diff review.

## Patch Bundle Policy

Builders cannot commit. The architect produces a patch bundle only, after:

- the frozen gate snapshot still matches,
- changed and untracked files are inside the lane's declared file set,
- the implementation diff has been read,
- deterministic `RUN:` gates have been graded by `check-runner.sh`,
- one graded item has been spot-checked during intent review,
- the lane patch passes `git apply --check`.

The architect writes one patch per accepted lane and a combined `final.patch`
under `.scratch/architect-loop/state/<slice>/`. `verdict.md` records the base
SHA, accepted/rejected lanes, gate ledger, changed files, and patch paths.

The loop stops after reporting the patch bundle and evidence paths. Applying,
staging, committing, pushing, opening issues, opening a PR, or publishing docs
requires a separate explicit human instruction after the patch is reviewed.

## Architect Fast Policy

`/architect-fast` is a deliberate light-lane exception for one bounded goal:
at most 3 file-disjoint Codex builder lanes and roughly 400 expected changed
lines. It preserves the Opus/Codex role split, detached ignored worktrees,
wrapper-owned run evidence, strict touch sets, and local patch-bundle finish.

It omits frozen gate files, the deterministic check-runner, per-lane judges,
the stress-test dispatch, and the watchdog. Because this fork has no immutable
tracker issue bodies, it snapshots and checksums the local spec/slices as a
stable acceptance packet without turning them into executable gates.
Builder-run focused tests and the combined full-suite run provide mechanical
evidence. One fresh Codex builder then reviews and fixes the combined candidate
in a new closing worktree; the architect reruns validation, checks the final
boundaries and size, and produces `final.patch` plus `verdict.md`.

This differs from original upstream's tracker/branch/merge/PR factory. The
local fast lane creates no external issues, durable branches, commits, merges,
PRs, or committed documentation. If the ceiling or risk is exceeded, it stops
before dispatch and recommends `/architect`.
