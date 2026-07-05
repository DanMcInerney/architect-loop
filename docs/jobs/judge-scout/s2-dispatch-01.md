# Job report: judge-scout/s2-dispatch-01

## Non-blank line counts

| file | before | after |
|---|---:|---:|
| skills/architect/dispatch.md | 582 | 543 |
| .claude/agents/architect-judge.md | 40 | 43 |
| docs/jobs/judge-scout/s2-dispatch-01.md | MISSING | 152 |

## Live dependency checks

Command:
```powershell
uv --version
```
Exit: 0
```text
uv 0.9.10 (44f5a14f4 2025-11-17)
```

Command:
```powershell
git --version
```
Exit: 0
```text
git version 2.51.2.windows.1
```

Command:
```powershell
$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
```
Exit: 0
```text
OK - 2 skills validated, v4 contracts clean
```

## Frozen RUN checks

Command:
```powershell
$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
```
Exit: 1
```text
FAIL - 3 problem(s):
  - skills/architect/dispatch.md: C5 judge template missing Per check:
  - skills/architect/dispatch.md: architect-judge-template missing re-run at least one RUN command
  - skills/architect/dispatch.md: architect-codex-judge-template missing re-run at least one RUN command
```

Command:
```powershell
git grep -F -c "Per check:" -- skills/architect/dispatch.md
```
Exit: 1
```text
```

Command:
```powershell
git grep -F -c -e "-> exit:" -- skills/architect/dispatch.md
```
Exit: 0
```text
skills/architect/dispatch.md:1
```

Command:
```powershell
git grep -F -c "match:" -- skills/architect/dispatch.md
```
Exit: 0
```text
skills/architect/dispatch.md:2
```

Command:
```powershell
git grep -F -c "## Scout dispatch" -- skills/architect/dispatch.md
```
Exit: 0
```text
skills/architect/dispatch.md:1
```

Command:
```powershell
if ((Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() -ne "" }).Count -le 545) { "BUDGET_OK" } else { "BUDGET_FAIL"; exit 1 }
```
Exit: 0
```text
BUDGET_OK
```

## Raw anchor evidence

Command:
```powershell
rg -n "Evidence rules:|Verdict format:|## Check-runner dispatch|Graded RUN grammar|Typed exits:|Exit 2 routes|## Scout dispatch|read-only code scout|NOT FOUND|No recommendations|Grill clause:|dangling anchor" skills/architect/dispatch.md
```
Exit: 0
```text
130:Evidence rules: read the checkrun evidence SUMMARY before intent review. Do not grade RUN items from the evidence file. Re-run exactly ONE graded RUN item and compare the verdicts; any mismatch is automatic INVALID with both outputs quoted. Missing or stale evidence (integrity false or freeze SHA mismatch) is INVALID, never FAIL.
131:Verdict format: Checks integrity: PASS | FAIL | INVALID with raw `git diff <freeze-sha>..HEAD -- docs/checks/`; Diff vs intent: PASS | FAIL | INVALID with file:line evidence; Spot-check: PASS | FAIL | INVALID with item and both quoted outputs; Slice verdict: PASS | FAIL | INVALID with one decisive reason.
148:Evidence rules: read the checkrun evidence SUMMARY before intent review. Do not grade RUN items from the evidence file. Re-run exactly ONE graded RUN item and compare the verdicts; any mismatch is automatic INVALID with both outputs quoted. Missing or stale evidence (integrity false or freeze SHA mismatch) is INVALID, never FAIL.
149:Verdict format: Checks integrity: PASS | FAIL | INVALID with raw `git diff <freeze-sha>..HEAD -- docs/checks/`; Diff vs intent: PASS | FAIL | INVALID with file:line evidence; Spot-check: PASS | FAIL | INVALID with item and both quoted outputs; Slice verdict: PASS | FAIL | INVALID with one decisive reason.
153:## Check-runner dispatch
155:Graded RUN grammar is normative from the frozen s1-runner contract: ``- RUN: `<command>` -> exit:<n>`` with optional ` match:"<substring>"`.
160:Typed exits: 0 = all RUN items pass; 2 = any RUN item fails; 5 = error, no partial evidence file left behind.
162:Exit 2 routes to the failure ladder with no judge dispatch; `loop.md` owns the full rule.
164:## Scout dispatch
169:You are a read-only code scout. Output path: <docs/runs/<run>/map.md>.
170:Return <= ~2,500 tokens. No recommendations.
172:If a requested category is absent, write `NOT FOUND: <category> - <searched paths>`.
188:Grill clause: every mechanical check MUST use `- RUN:` form with a `->` expectation; a mechanical RUN item without an expectation is a check defect.
191:For every delete/rename, grep the repo for references and verify the owning job boundary covers them or a dependency edge orders the fix. For every NEW artifact path, run `git check-ignore <path>` and flag ignored paths. If a run map exists, sample map entries and verify each file:line anchor resolves; any dangling anchor is a check defect.
286:Typed exits:
```

Command:
```powershell
rg -n "CHECKRUN SUMMARY|Do not re-grade|Re-run exactly ONE graded RUN|Return verdicts only|Do not edit files|checks-integrity|diff-vs-intent|spot-check" .claude/agents/architect-judge.md
```
Exit: 0
```text
16:  dependent steps and the single spot-check re-run.
23:- Read the checkrun evidence `CHECKRUN SUMMARY` before intent review. Missing
25:- Do not re-grade RUN items from the evidence file. Re-run exactly ONE graded
26:  RUN item as a spot-check and compare verdicts. Any mismatch is automatic
30:- Return verdicts only: checks-integrity PASS / FAIL / INVALID, diff-vs-intent
31:  PASS / FAIL / INVALID, spot-check PASS / FAIL / INVALID with item and both
46:Do not edit files, do not fix failures, do not stage changes, do not commit,
```

## Boundary evidence

Command:
```powershell
git diff -- docs/checks
```
Exit: 0
```text
```

Command:
```powershell
git status --short
```
Exit: 0
```text
 M .claude/agents/architect-judge.md
 M skills/architect/dispatch.md
?? docs/jobs/judge-scout/
```

Command:
```powershell
git diff --stat -- skills/architect/dispatch.md .claude/agents/architect-judge.md
```
Exit: 0
```text
 .claude/agents/architect-judge.md |  19 ++++---
 skills/architect/dispatch.md      | 115 +++++++++++---------------------------
 2 files changed, 45 insertions(+), 89 deletions(-)
warning: in the working copy of '.claude/agents/architect-judge.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
```

MIRROR: ORCHESTRATOR

STATUS: COMPLETE_WITH_CONCERNS (validator command fails because live tests/validate_skills.py still requires retired C5 strings "Per check:" and "re-run at least one RUN command"; tests/ is outside this job boundary)
