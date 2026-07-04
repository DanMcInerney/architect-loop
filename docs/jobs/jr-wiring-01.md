# PHASE 0

Required input verification:

```text
git.exe rev-parse HEAD
1473c78cf443f2c0876bfc058b934e1bec7a7a48

Test-Path -LiteralPath docs/checks/jr-wiring.md
True
```

Plan:

1. Update `skills/architect/dispatch.md` only at the requested judge templates, new check-runner dispatch section location, and stress-test template.
2. Update `skills/architect/loop.md` only in `## Factory block procedure` Job DONE text and `## Verdict comments`.
3. Update `skills/architect/SKILL.md` only in Hard Rule 3 and Step 4 On-DONE text.
4. Run the frozen `docs/checks/jr-wiring.md` commands and size guards.
5. Leave `docs/checks/**`, runner scripts, tests, README, DESIGN, tracker/research/status/watchdog files untouched.

Disagreements:

None recorded.

Checked before finding none:

```text
docs/spec/judge-runner.md: D1 requires `- RUN:` grammar; D4 requires judge evidence consumption and spot-check; D5 requires loop/SKILL.md wiring.
docs/checks/jr-wiring.md: acceptance owns only skills/architect/SKILL.md, skills/architect/loop.md, skills/architect/dispatch.md.
git.exe grep anchors:
skills/architect/dispatch.md:90:## C5 judge delegation template
skills/architect/dispatch.md:98:<!-- architect-judge-template:start -->
skills/architect/dispatch.md:119:<!-- architect-judge-template:end -->
skills/architect/dispatch.md:121:## Codex judge delegation template
skills/architect/dispatch.md:127:<!-- architect-codex-judge-template:start -->
skills/architect/dispatch.md:164:<!-- architect-codex-judge-template:end -->
skills/architect/dispatch.md:166:## Stress-test delegation template
skills/architect/dispatch.md:172:<!-- architect-stress-test-template:start -->
skills/architect/dispatch.md:194:<!-- architect-stress-test-template:end -->
skills/architect/loop.md:17:3. **Wake on one event**, exactly one of:
skills/architect/loop.md:59:## Verdict comments
tests/validate_skills.py:233:        r"<!-- architect-judge-template:start -->\n```text\n(.*?)\n```\n<!-- architect-judge-template:end -->",
```

MIRROR: ORCHESTRATOR

# Evidence

Frozen mechanical checks:

```text
COMMAND: git.exe grep -c "## Check-runner dispatch" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
COMMAND: git.exe grep -c -- "- RUN:" skills/architect/dispatch.md
skills/architect/dispatch.md:3
EXIT: 0
COMMAND: git.exe grep -c "max_output_lines" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
COMMAND: git.exe grep -c "CHECKRUN: ERROR" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
COMMAND: git.exe grep -c "checkrun" -- skills/architect/dispatch.md
skills/architect/dispatch.md:6
EXIT: 0
COMMAND: git.exe grep -c "re-run at least one RUN command" -- skills/architect/dispatch.md
skills/architect/dispatch.md:2
EXIT: 0
COMMAND: git.exe grep -c "Source: evidence-file" -- skills/architect/dispatch.md
skills/architect/dispatch.md:2
EXIT: 0
COMMAND: git.exe grep -c "never FAIL" -- skills/architect/dispatch.md
skills/architect/dispatch.md:2
EXIT: 0
COMMAND: git.exe grep -c "evidence_out" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
COMMAND: git.exe grep -c "architect-judge-template:start" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
COMMAND: git.exe grep -c "architect-codex-judge-template:start" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
COMMAND: git.exe grep -c "MUST use" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
COMMAND: git.exe grep -c "check-runner" -- skills/architect/loop.md
skills/architect/loop.md:2
EXIT: 0
COMMAND: git.exe grep -c "checkrun" -- skills/architect/loop.md
skills/architect/loop.md:2
EXIT: 0
COMMAND: git.exe grep -c "check-runner" -- skills/architect/SKILL.md
skills/architect/SKILL.md:2
EXIT: 0
```

Size guards:

```text
COMMAND: (Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() }).Count
208
COMMAND: (Get-Content skills/architect/loop.md | Where-Object { $_.Trim() }).Count
100
COMMAND: (Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() }).Count
492
```

Judge-only quote evidence:

```text
skills/architect/SKILL.md:36:3. **Nobody grades their own work.** Builders report raw evidence only. A fresh, independent orchestrator-tier judge checks intent. Frozen checks are executed by the deterministic check-runner; the judge grades the evidence and spot-checks. The orchestrator may not turn a judge FAIL into a merge.
skills/architect/loop.md:18:   - **Job DONE.** Ordering: write the runner config; launch `check-runner.ps1`
skills/architect/loop.md:19:     or `check-runner.sh` as a background process whose exit is the next wake; commit the checkrun artifact `docs/jobs/<issue-slug>-checkrun.md`; then send the fixed judge template from `dispatch.md` to one fresh judge subagent with the evidence path. Record the verdict in an issue comment (see Verdict comments); merge on PASS, diagnose on FAIL (see Failure ladder).
skills/architect/dispatch.md:200:Grill clause: every mechanical check MUST use `- RUN:` form; a mechanical check not in RUN form is a check defect.
skills/architect/SKILL.md:200:- On DONE, write the runner config, launch the check-runner in the background, let its exit wake the loop, commit the checkrun evidence file, then send a fresh, independent orchestrator-tier judge with the evidence path.
skills/architect/dispatch.md:165:<!-- architect-codex-judge-template:end -->
skills/architect/dispatch.md:167:## Check-runner dispatch
skills/architect/dispatch.md:188:## Stress-test delegation template
```

Validator:

```text
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr-wiring'; uv run --no-project python tests/validate_skills.py
OK - 2 skills validated, v4 contracts clean
```

Touch-set audit:

```text
git.exe status --short
 M skills/architect/SKILL.md
 M skills/architect/dispatch.md
 M skills/architect/loop.md
?? docs/jobs/jr-wiring-01.md

git.exe diff -- docs/checks
<no output>

git.exe diff --check
warning: in the working copy of 'skills/architect/SKILL.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/loop.md', LF will be replaced by CRLF the next time Git touches it
exit 0
```
STATUS: COMPLETE
