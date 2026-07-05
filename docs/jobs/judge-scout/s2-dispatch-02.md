# Job report: judge-scout/s2-dispatch-02

## Non-blank line counts

| file | before | after |
|---|---:|---:|
| skills/architect/dispatch.md | 582 | 545 |
| .claude/agents/architect-judge.md | 40 | 46 |
| tests/validate_skills.py | 951 | 976 |
| docs/jobs/judge-scout/s2-dispatch-02.md | MISSING | 221 |

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
python --version
```
Exit: 1
```text
Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.
```

Command:
```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run python --version
```
Exit: 0
```text
Python 3.12.4
```

## Frozen RUN checks

Command:
```powershell
$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
```
Exit: 0
```text
OK - 2 skills validated, v4 contracts clean
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
git grep -F -c "Per check:" -- tests/validate_skills.py
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
skills/architect/dispatch.md:2
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
137:Evidence rules: read the checkrun evidence SUMMARY before intent review. Do not grade RUN items from the evidence file. Re-run exactly ONE graded RUN item and compare the verdicts; any mismatch is automatic INVALID with both outputs quoted. Missing or stale evidence (integrity false or freeze SHA mismatch) is INVALID, never FAIL.
139:Verdict format: Checks integrity: PASS | FAIL | INVALID with raw `git diff <freeze-sha>..HEAD -- docs/checks/`; Diff vs intent: PASS | FAIL | INVALID with file:line evidence; Spot-check: PASS | FAIL | INVALID with item and both quoted outputs; Slice verdict: PASS | FAIL | INVALID with one decisive reason.
163:Evidence rules: read the checkrun evidence SUMMARY before intent review. Do not grade RUN items from the evidence file. Re-run exactly ONE graded RUN item and compare the verdicts; any mismatch is automatic INVALID with both outputs quoted. Missing or stale evidence (integrity false or freeze SHA mismatch) is INVALID, never FAIL.
165:Verdict format: Checks integrity: PASS | FAIL | INVALID with raw `git diff <freeze-sha>..HEAD -- docs/checks/`; Diff vs intent: PASS | FAIL | INVALID with file:line evidence; Spot-check: PASS | FAIL | INVALID with item, executor, and both quoted outputs; Slice verdict: PASS | FAIL | INVALID with one decisive reason.
169:## Check-runner dispatch
171:Graded RUN grammar is normative from the shipped s1 runner in `skills/architect/check-runner.ps1`: first backtick span is the command; expectation begins immediately after the closing backtick as ``-> exit:<n>`` with optional `match:"<substring>"`. `match:` is a fixed, case-sensitive stdout substring check, never regex. Text after the expectation is judge-facing prose; non-RUN items are judge-only. A RUN item without an expectation exits 5 with `CHECKRUN: ERROR missing RUN expectation`, and no partial evidence is kept.
175:Typed exits: 0 = all RUN items pass; 2 = any RUN item fails; 5 = error, no partial evidence file left behind.
176:Launch pattern: run `skills/architect/check-runner.ps1` or `check-runner.sh` in the background and commit `docs/jobs/<run>/<issue-slug>-checkrun.md` before judge dispatch on exit 0. Exit 2 routes to the failure ladder with no judge dispatch; `loop.md` owns the full rule.
178:## Scout dispatch
183:You are a read-only code scout. Output path: <docs/runs/<run>/map.md>.
184:Return <= ~2,500 tokens. No recommendations.
186:Every entry must carry a real file:line anchor. If a requested category is absent, write `NOT FOUND: <category> - <searched paths>`. No implementation plan, no edits.
199:Grill clause: every mechanical check MUST use `- RUN:` form with a `->` expectation; a RUN item without an expectation is a check defect.
204:If a run map exists, sample map entries and verify each file:line anchor resolves; a dangling anchor is a check defect.
295:Typed exits:
```

Command:
```powershell
rg -n "CHECKRUN SUMMARY|Do not re-grade|Re-run exactly ONE graded RUN|automatic|Return verdicts only|Do not edit files|checks-integrity|diff-vs-intent|spot-check|read-only" .claude/agents/architect-judge.md
```
Exit: 0
```text
3:description: Runs frozen architect checks as a fresh read-only judge, verifies checks integrity and diff intent, and returns PASS/FAIL/INVALID verdicts with raw evidence only.
16:  dependent steps and the single spot-check re-run.
23:- Read the checkrun evidence `CHECKRUN SUMMARY` before intent review. Missing
25:- Do not re-grade RUN items from the evidence file. Re-run exactly ONE graded
26:  RUN item as a spot-check and compare verdicts. Any mismatch is automatic
32:- Return verdicts only: checks-integrity PASS / FAIL / INVALID, diff-vs-intent
33:  PASS / FAIL / INVALID, spot-check PASS | FAIL | INVALID with item and both
40:  with read-only tools (claude-code #60237 silently drops those two
49:Do not edit files, do not fix failures, do not stage changes, do not commit,
```

Command:
```powershell
rg -n "architect-judge-template|architect-codex-judge-template|architect-stress-test-template|architect-monitor-fallback-template|read the checkrun evidence SUMMARY|Do not grade RUN items|Re-run exactly ONE graded RUN item|mismatch is automatic INVALID|missing .*marker block|independent reads exactly once|before grading; grade RUN items" tests/validate_skills.py
```
Exit: 0
```text
269:        r"<!-- architect-judge-template:start -->\n```text\n(.*?)\n```\n<!-- architect-judge-template:end -->",
285:        "read the checkrun evidence SUMMARY",
286:        "Do not grade RUN items from the evidence file",
287:        "Re-run exactly ONE graded RUN item",
288:        "mismatch is automatic INVALID",
319:        "architect-judge-template",
320:        "architect-codex-judge-template",
321:        "architect-stress-test-template",
322:        "architect-monitor-fallback-template",
329:            errors.append(f"skills/architect/dispatch.md: missing {marker} marker block")
332:    for marker in ("architect-judge-template", "architect-codex-judge-template"):
337:            "read the checkrun evidence SUMMARY",
338:            "Do not grade RUN items from the evidence file",
339:            "Re-run exactly ONE graded RUN item",
340:            "mismatch is automatic INVALID",
347:        if "before grading; grade RUN items from the evidence file" in block:
355:                f"{marker} must contain independent reads exactly once"
```

Command:
```powershell
rg -n "ParseRunExpectation|missing RUN expectation|IndexOf|CHECKRUN SUMMARY|exit 2|exit 5|expected:|verdict:" skills/architect/check-runner.ps1
```
Exit: 0
```text
24:    exit 5
131:function ParseRunExpectation($Text, $File, $LineNo) {
133:    if (-not $m.Success) { StopRun "missing RUN expectation ${File}:$LineNo" }
167:    exit 5
211:        $expectation = ParseRunExpectation $m.Groups[2].Value $checkFile $lineNo
231:    if ($run.Expected.Match -ne $null -and $result.Stdout.IndexOf($run.Expected.Match, [System.StringComparison]::Ordinal) -lt 0) { $verdict = "FAIL" }
241:    [void]$e.Add("expected: $($run.Expected.Text)")
242:    [void]$e.Add("verdict: $verdict")
246:[void]$e.Add("CHECKRUN SUMMARY: run_items=$($runs.Count) pass=$passCount fail=$failCount")
256:if ($failCount -gt 0) { exit 2 }
```

Command:
```powershell
rg -n "## Scout dispatch|dispatch.md.*Scout dispatch" skills/architect/SKILL.md skills/architect/dispatch.md
```
Exit: 0
```text
skills/architect/SKILL.md:23:- dispatch.md sections `## Scout dispatch`, `## Monitor dispatch`
skills/architect/SKILL.md:87:In parallel with that batch and timer, dispatch one read-only code scout at the builders model using the `scout` job shape and `dispatch.md` `## Scout dispatch`; commit its returned map at `docs/runs/<run>/map.md`. The spec and every issue cite the map pointer.
skills/architect/dispatch.md:178:## Scout dispatch
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
 M tests/validate_skills.py
?? docs/jobs/judge-scout/s2-dispatch-02.md
```

Command:
```powershell
git diff --stat -- skills/architect/dispatch.md .claude/agents/architect-judge.md tests/validate_skills.py
```
Exit: 0
```text
 .claude/agents/architect-judge.md | 18 +++++---
 skills/architect/dispatch.md      | 96 ++++++++++++---------------------------
 tests/validate_skills.py          | 35 ++++++++++++--
 3 files changed, 71 insertions(+), 78 deletions(-)
warning: in the working copy of '.claude/agents/architect-judge.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
```

MIRROR: ORCHESTRATOR

STATUS: COMPLETE
