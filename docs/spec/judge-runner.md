# Spec: judge-runner — deterministic check execution, judge verifies instead of runs

Status: APPROVED in-session 2026-07-04.
Approval record (verbatim, in-session human authorization): "go ahead and
implement your judge offloading of checks. If you see any other areas to save
tokens on the orchestrator model by offloading work that doesn't need an LLM,
then tell me about those after you implement the judge offloading"
Author: orchestrator session, 2026-07-04.
Evidence base: 135 `command → expected` items across the 15 frozen check
files in `docs/checks/` (~9 per file; `tracker-adapter.md` is 17-of-18
mechanical). The judge inherits the orchestrator model, so today every one of
those commands is a tool round trip inside a frontier-model session whose
transcript grows per result. The intelligence required for those steps is
zero; the intelligence the judge exists for (diff-vs-intent — it caught the
masked README-link failure five green checks missed) is a small fraction of
its current token spend.

## Problem

Judging conflates two different kinds of work: (a) executing frozen check
commands and capturing raw outcomes — deterministic, no judgment; (b) grading
— evidence vs expected outcomes, checks integrity, diff-vs-intent, the slice
verdict. Both currently run inside one orchestrator-tier LLM session, so the
mechanical majority is billed at frontier-model prices, and shell-dependent
checks force cross-family codex judges whenever CLI subagent spawns lose
their shell tools (D12).

## Goal

Split them. A deterministic script (`check-runner`) executes every runnable
check exactly as written and records raw evidence plus integrity facts; the
orchestrator-tier judge reads that evidence file once, grades it, does
diff-vs-intent, and rules. The judge keeps the right to re-run anything
(spot-check honesty guard). Grading never moves to a cheaper model and never
moves into the script: the runner records facts, only the judge produces
verdicts. Hard Rule 3's intent — nobody grades their own work, fresh
orchestrator-tier judgment — is unchanged; only the *execution* of frozen
commands is offloaded, and offloaded below the LLM layer entirely.

## Non-goals

- No LLM check-runner. A builder-tier agent costs tokens and can misreport;
  a script cannot fabricate an exit code. (Design-it-twice, sketch B.)
- No re-freezing or rewriting of the 15 existing check files; the RUN
  grammar applies to checks authored from now on.
- No change to judge model routing (`model: inherit` stands), no change to
  the codex-judge template's existence (it remains the cross-family option
  for high-stakes review; it should no longer be *forced* by shell checks).
- No automatic pass/fail computation in the runner, not even for exact-match
  expectations. The moment the runner grades, it becomes a judge nobody
  audits.

## Design

### D1. RUN grammar for check files (design-it-twice record)

Sketches considered: (A) heuristic "first backtick span on a `- ` line is a
command" — rejected: existing files contain non-command backtick spans in
prose (`git grep -c` as a fragment, quoted section titles), so false
positives are structural; (B) explicit `- RUN:` marker — chosen; (C) fenced
` ```run ` blocks — rejected: heavier authoring churn and it separates the
command from its inline `→ expected` annotation, which judges and the grill
read together.

Grammar, normative from this spec on:

- A runnable check is a list line beginning `- RUN:` whose first single
  backtick span is the complete command, executable verbatim in the file's
  named executor. Everything after the closing backtick (typically
  `→ <expected>`) is judge-facing prose the runner ignores.
- The check file header names the executor (`Executor:` line, existing
  convention). One executor per file.
- Items without `RUN:` are judge-only (quote/verbatim/contract items).
- The decomposition grill gains one clause: every mechanical check MUST use
  `- RUN:` form; a mechanical check not in RUN form is a check defect.

### D2. check-runner scripts

`skills/architect/check-runner.ps1` (Windows) and `check-runner.sh` (POSIX),
siblings of watchdog/status. Deterministic, non-grading, read-only except
its evidence output file. Behavior:

1. Read config JSON (Interface contract below).
2. Integrity facts (recorded, never judged): the check file's content on
   disk hashes equal to `git show <freeze_sha>:<check_file>`; `git -C
   <workdir> rev-parse HEAD`; `git -C <workdir> diff --name-only
   <freeze_sha>..HEAD` in full; whether any changed path is under
   `docs/checks/`.
3. Parse RUN lines per D1, preserving section headers and file line numbers.
4. Execute each command in order, cwd = workdir, via the file's executor;
   capture exit code, wall ms, and output capped at `max_output_lines`
   (default 60) with the untruncated byte count. A command that errors is
   evidence, not a runner failure; execution always continues.
5. Write the evidence file and exit 0. Exit 5 (`CHECKRUN: ERROR <reason>`)
   only when evidence cannot be produced at all: unreadable config, missing
   check file, git itself unavailable.

### D3. Evidence file

`docs/jobs/<issue-slug>-checkrun.md`, orchestrator-committed to the factory
branch before judge dispatch (same durability rule as rulings files):

```markdown
# Checkrun: <issue-slug>
generated: <iso8601>  runner: <ps1|sh>  config: <path>
check_file: <path>  freeze_sha: <sha>
integrity: check_file_matches_freeze=<true|false> head=<sha>
changed_files: <n> listed below; docs_checks_touched=<true|false>
<one line per changed path>

## <section header> line <n>
$ <command verbatim>
exit: <code>  ms: <n>  bytes: <n>[ truncated]
<captured output>
```

### D4. Judge consumes evidence; spot-check guard

Both judge templates in `dispatch.md` change from "run each check command"
to: read the checkrun evidence file; grade each RUN item's captured evidence
against the frozen expected outcome; execute judge-only items yourself;
**re-run at least one RUN command of your choosing and compare against the
evidence file — any mismatch is an automatic INVALID with both outputs
quoted**. Missing or stale evidence file (freeze SHA mismatch, integrity
false) → INVALID, never FAIL. Diff-vs-intent, checks-integrity verdict, and
the slice call remain judge work, unchanged.

### D5. Loop wiring

`loop.md` "On DONE": orchestrator writes the runner config, launches
check-runner as a background process (its exit is the wake event, watchdog
pattern), commits the evidence file, then dispatches the judge with the
evidence path in its context. `SKILL.md` step 4 sentence updated to match;
Hard Rule 3 gains the clause "frozen checks are executed by the
deterministic check-runner; the judge grades the evidence and spot-checks".
D12 consequence recorded: shell-dependent checks no longer force the codex
judge path, because execution happens outside any subagent sandbox.

## Interface contract (consumed by all slices)

Runner config JSON, written by the orchestrator per judgment:

```json
{
  "check_file": "docs/checks/<slug>.md",
  "workdir": "<worktree or repo path>",
  "freeze_sha": "<sha>",
  "evidence_out": "docs/jobs/<issue-slug>-checkrun.md",
  "executor": "powershell|bash",
  "max_output_lines": 60
}
```

Typed exits: 0 = evidence file written; 5 = `CHECKRUN: ERROR <reason>` on
stdout, no partial evidence file left behind (write temp, move on success).
The runner never posts to the tracker, never grades, never writes anything
except `evidence_out`.

## Assumptions

- A1. RUN grammar is prospective only; the 15 existing frozen check files
  stay as-is and any re-judgment of them uses the old judge path.
- A2. Executor values are exactly `powershell` and `bash`; one per check
  file; no per-line executor overrides.
- A3. 60-line output cap with byte count is sufficient; the judge re-runs a
  command when truncation hides what it needs.
- A4. Evidence files are committed (not gitignored) — they are raw
  artifacts like job reports and rulings.
- A5. The codex-judge template survives unmodified except for the evidence
  consumption paragraph shared with the C5 template.

## Validation strategy

Fixture-based, no network: a fixture check file containing (a) a RUN line
that succeeds with known output, (b) a RUN line that exits nonzero, (c) a
prose line with a backtick span and NO RUN marker, (d) a judge-only quote
item. Run the runner against it in a scratch git state; assert the evidence
file contains exactly two `$` blocks with correct exit codes, the non-RUN
span was never executed, integrity fields are present, and exit code is 0.
Config-error path asserts exit 5 and no evidence file. Skill-text slices are
checked with the existing grep-anchor style; validator slice must keep
`tests/validate_skills.py` green end-to-end.

## Decomposition sketch

- JR1 `runner-scripts`: check-runner.ps1/.sh + fixtures. Touches only new
  files. No blockers.
- JR2 `skill-wiring`: SKILL.md, loop.md, dispatch.md (RUN grammar section,
  judge template edits, runner dispatch section, grill clause). Disjoint
  from JR1 by file; both reference this spec's Interface contract. No
  blockers.
- JR3 `validator`: tests/validate_skills.py contract checks for the new
  sibling scripts and dispatch anchors. Blocked by JR1 and JR2 (its checks
  reference their artifacts).
- JR4 `docs` (finish job): README + DESIGN.md evidence, docs/solutions
  debt. Blocked by all.
