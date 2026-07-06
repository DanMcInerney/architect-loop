# Job report: skill-library/s10-01 (s10-trigger-allowlist)

Job shape: ship
Frozen check: docs/checks/skill-library/s10-trigger-allowlist.md (freeze commit c7f38b9, read-only, not touched)
Worktree HEAD after FF: `2980807` (job skill-library/s9-01, merged with ancestry verified via
`git merge-base --is-ancestor HEAD 29808074675a04704e1160ce2d9cc75097242259` then
`git merge --ff-only 29808074675a04704e1160ce2d9cc75097242259`)

## PHASE 0

Posted to issue #113: https://github.com/DanMcInerney/architect-loop/issues/113#issuecomment-4888747999

No disagreements with the spec. Checked:
- `skills/architect/trigger-eval.sh` line 103 (awk regex inside `parse_fixture()`) hardcodes
  `SKILL: (architect|architect-research)$`.
- `skills/architect/trigger-eval.ps1` line 41 (`Parse-Fixture` function) hardcodes the identical
  two-name alternation via PowerShell `-match`.
- `docs/evals/trigger-prompts.md` already carries the seven stage-skill fixture blocks
  (codebase-design, to-spec, to-issues, frozen-checks, tdd, adversarial-review, cohesion-review),
  merged by s9 — confirmed by reading the file (lines 89-143).
- Both scripts' fixture-parsing logic is otherwise structurally identical, so extending the same
  alternation string in both keeps them in sync — matches the spec's "fix BOTH scripts identically"
  instruction.

## Change made

Allowlist-only edit, 2 lines changed total (1 per script):

```
diff --git a/skills/architect/trigger-eval.ps1 b/skills/architect/trigger-eval.ps1
@@ -38,7 +38,7 @@ function Parse-Fixture($Path) {
-            if ($lines[$i + 1] -match '^\s+SKILL: (architect|architect-research)$') {
+            if ($lines[$i + 1] -match '^\s+SKILL: (architect|architect-research|codebase-design|to-spec|to-issues|frozen-checks|tdd|adversarial-review|cohesion-review)$') {

diff --git a/skills/architect/trigger-eval.sh b/skills/architect/trigger-eval.sh
@@ -100,7 +100,7 @@ parse_fixture() {
-      if (skill_line !~ /^[[:space:]]+SKILL: (architect|architect-research)$/) { ... }
+      if (skill_line !~ /^[[:space:]]+SKILL: (architect|architect-research|codebase-design|to-spec|to-issues|frozen-checks|tdd|adversarial-review|cohesion-review)$/) { ... }
```

`git diff --stat` confirms: `2 files changed, 2 insertions(+), 2 deletions(-)` — no other files touched.
No typed-exit, flag, or grammar-structure change in either script; only the alternation's name set
grew from 2 to 9.

## RED -> GREEN parse evidence

### Pre-fix (RED): both scripts reject a stage-skill block

**sh script**, running the full `trigger-eval.sh --limit 1` (real script, real code path):
```
$ bash skills/architect/trigger-eval.sh --limit 1
EXIT:1
ERROR	invalid SKILL line after prompt near line 89:   SKILL: codebase-design
```
(Exit surfaces as 1 at the script's top level because `rows=$(parse_fixture) || exit 1` maps any
non-zero `parse_fixture` exit to `exit 1` for the caller — but the fixture-parsing `awk` block
itself terminates with `exit 2` internally, per spec wording "exits 2 at parse before any model
call." To show that exact internal exit 2 unambiguously, I also ran the parse_fixture awk snippet
standalone against the unmodified fixture:)
```
$ awk '<parse_fixture body, pre-fix regex>' docs/evals/trigger-prompts.md
AWK_EXIT:2
ERROR	invalid SKILL line after prompt near line 89:   SKILL: codebase-design
```
This proves: pre-fix, the first stage-skill block (line 89, `SKILL: codebase-design`) is rejected
by the awk grammar with exit 2, before any prompt row for that block is ever emitted, and before
any `claude` invocation for later rows would occur.

**ps1 script**, running the full `trigger-eval.ps1 -Limit 1` (real script, real code path, via
`powershell -NoProfile -File`):
```
EXIT:1
powershell : invalid SKILL line after prompt at line 89:   SKILL: codebase-design
    + CategoryInfo          : NotSpecified: (invalid SKILL l...codebase-design:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
    + CategoryInfo          : OperationStopped: (invalid SKILL l...codebase-design:String) [], RuntimeException
    + FullyQualifiedErrorId : invalid SKILL line after prompt at line 89:   SKILL: codebase-design
```
`$ErrorActionPreference = "Stop"` turns the `throw` into a terminating error; PowerShell reports
process exit code 1. This proves the ps1 `Parse-Fixture` function rejects the same line 89 block
pre-fix, before any `claude` invocation.

### Post-fix (GREEN): both scripts parse the full fixture cleanly

**Direct awk parse of the full fixture** with the post-fix regex (all 34 prompt blocks, including
all seven new stage-skill blocks):
```
AWK_EXIT:0
(stderr empty)
34 rows emitted, e.g. last rows:
30  tdd                 no-trigger  Rename this variable across the file and fix the imports.
31  adversarial-review  trigger     You are a fresh reviewer; run adversarial-review ...
32  adversarial-review  no-trigger  Proofread this README paragraph for typos.
33  cohesion-review     trigger     Every issue in the run is closed; run the cohesion-review ...
34  cohesion-review     no-trigger  Summarize what changed in the last commit.
```

**Full sh script run** (`trigger-eval.sh --limit 1 --claude .architect/tmp/s10/fake-claude.sh`,
a local stub that only echoes a JSON line and exits 0 — no headless `claude` session was
spawned). Because `parse_fixture()` parses the *entire* fixture file before `--start`/`--limit`
row selection is applied, this exercises the real parser against all 34 blocks, not just row 1:
```
EXIT:0
FIXTURE: .../docs/evals/trigger-prompts.md
PROMPTS: 1
COMMAND[1]: .architect/tmp/s10/fake-claude.sh -p "/architect continue the factory run..." ...
INDEX  SKILL      EXPECT   DETECTED  RESULT  EXIT  PROMPT
1      architect  trigger  trigger   PASS    0     /architect continue the factory run...
NOT_VIABLE: no reliable Skill invocation event was observed in Claude Code stream-json output.
```

**Full ps1 script run** (`trigger-eval.ps1 -Limit 1 -Claude .architect\tmp\s10\fake-claude.cmd`,
a local `.cmd` stub echoing a JSON line and exiting 0 — no headless `claude` session was spawned).
`Parse-Fixture` also parses the whole file up front, so this proves the real ps1 parser accepts
all 34 blocks:
```
EXIT:0
FIXTURE: ...\docs\evals\trigger-prompts.md
PROMPTS: 1
COMMAND[1]: .architect\tmp\s10\fake-claude.cmd -p "/architect continue the factory run..." ...
INDEX  SKILL      EXPECT   DETECTED  RESULT  EXIT  PROMPT
1      architect  trigger  trigger   PASS    0     /architect continue the factory run...
NOT_VIABLE: no reliable Skill invocation event was observed in Claude Code stream-json output.
```

**What was proven, per script, exactly:**
- sh: the real `parse_fixture()` awk grammar, pre-fix, rejects the fixture at the first
  stage-skill block with an internal `exit 2` (shown via standalone awk invocation) and a
  top-level script exit 1 (via `rows=$(parse_fixture) || exit 1`); post-fix, the same real
  `parse_fixture()` parses all 34 blocks with zero stderr and exit 0, and a full run of the real
  script (stub `claude` binary, no headless session) completes end-to-end with exit 0.
- ps1: the real `Parse-Fixture` function, pre-fix, throws a terminating error on the same
  stage-skill block (process exit 1, since ps1 has no dedicated typed parse-exit — it uses
  `throw`/`$ErrorActionPreference=Stop`); post-fix, a full run of the real script (stub `.cmd`
  binary, no headless session) completes end-to-end with exit 0, proving `Parse-Fixture` accepted
  all 34 blocks (it parses the whole file before `-Start`/`-Limit` selection, so row-1-only
  selection does not limit what was parsed). No live/headless `claude` session was invoked in any
  of the four post-fix runs shown above — both used local stub executables.

## Frozen check RUN items (all four, verbatim)

```
$ bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/trigger-eval.sh || { echo "SH_MISSING: $s"; exit 3; }; done; echo SH_ALLOWLIST_OK'
SH_ALLOWLIST_OK
EXIT:0

$ bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/trigger-eval.ps1 || { echo "PS_MISSING: $s"; exit 3; }; done; echo PS_ALLOWLIST_OK'
PS_ALLOWLIST_OK
EXIT:0

$ bash -c 'grep -qF "architect-research" skills/architect/trigger-eval.sh && grep -qF "architect-research" skills/architect/trigger-eval.ps1 && echo EXISTING_KEPT'
EXISTING_KEPT
EXIT:0

$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
OK - 9 skills validated, v4 contracts clean
EXIT:0
```

All four RUN items pass with the exact expected exit code (0) and match string.

## Executor record

All frozen-check RUN items and RED-evidence direct-awk tests ran via the Bash tool (Git Bash,
matching the frozen check's "Preferred executor: bash"). Both post-fix full-script runs ran via
Bash (`.sh`) and PowerShell tool (`powershell -NoProfile -File ...ps1`) respectively — Bash was
available throughout this session (no shell-strip encountered), so PowerShell was used only where
the target under test is itself a PowerShell script.

## Boundary compliance

- Touched only: `skills/architect/trigger-eval.sh`, `skills/architect/trigger-eval.ps1`,
  `docs/jobs/skill-library/s10-trigger-allowlist-01.md` (this report).
- `docs/checks/skill-library/s10-trigger-allowlist.md` was read only, never edited.
- No commits made (per instructions).
- Temp/scratch files (stub executables, RED/GREEN capture output) live under
  `.architect/tmp/s10/`, inside the workspace as required; not part of the tracked diff.

## Mirror

Posted PHASE 0 comment to issue #113 (link above). Final STATUS line will also be posted as an
issue comment; if `gh` is unavailable at that point this report will say `MIRROR: ORCHESTRATOR`
instead.

STATUS: COMPLETE
