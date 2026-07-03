# tuning-docs-01

## PHASE 0

Plan:
- Verify `HEAD` and `docs/checks/tuning-docs.md`.
- Verify freeze commit `6214c29` is an ancestor of `HEAD`.
- Read `docs/checks/tuning-docs.md`, `docs/spec/loop-tuning.md`, `README.md`, `DESIGN.md`, `CONTEXT.md`, and cited evidence files.
- Edit only `README.md`, `DESIGN.md`, and `CONTEXT.md`.
- Run every check in `docs/checks/tuning-docs.md` sequentially.
- Record verbatim command output.

Disagreements:
- `C:\Users\danhm\.agents\skills\implement\SKILL.md` says "Commit your work to the current branch." The job instruction says "Do NOT commit and do NOT run git add / git mv"; this report follows the job instruction.

Checked before concluding issue/spec sound:
- `docs/spec/loop-tuning.md` A2 requires updating `DESIGN.md` approval entry without deleting default-deny evidence.
- `docs/checks/tuning-docs.md` owns `README.md`, `DESIGN.md`, and `CONTEXT.md`.
- `README.md` has old 7-day approval language.
- `DESIGN.md` has the existing default-deny approval entry and watchdog entry to update.
- `CONTEXT.md` has the Spec approval glossary entry to update.

MIRROR: ORCHESTRATOR

## Input Verification

Command:
```powershell
git log -1 --oneline
```
Output:
```text
c2f1da3 merge job tuning-watchdog-01 (judge PASS, #49)
```

Command:
```powershell
Test-Path -LiteralPath docs/checks/tuning-docs.md; if (Test-Path -LiteralPath docs/checks/tuning-docs.md) { Get-Item -LiteralPath docs/checks/tuning-docs.md | Select-Object -ExpandProperty FullName }
```
Output:
```text
True
C:\Users\danhm\architect-loop\.architect\wt\tuning-docs-01\docs\checks\tuning-docs.md
```

Command:
```powershell
git merge-base --is-ancestor 6214c29 HEAD; if ($LASTEXITCODE -eq 0) { '6214c29 is ancestor of HEAD' } else { "6214c29 ancestor check failed: exit $LASTEXITCODE"; exit $LASTEXITCODE }
```
Output:
```text
6214c29 is ancestor of HEAD
```

## TD1

Command:
```powershell
git grep -ciE "5 minutes|five minutes" -- README.md
```
Output:
```text
README.md:2
```

Command:
```powershell
git grep -ci "STATUS" -- README.md
```
Output:
```text
README.md:14
```

Command:
```powershell
git grep -n -C 2 "STATUS" -- README.md
```
Output:
```text
README.md-116-     for stalls (output-byte growth, process CPU, repeated-command tails)
README.md-117-     and exits with typed evidence. Done means the job report's final
README.md:118:     non-blank line starts with `STATUS:`. It never kills and never decides;
README.md-119-     the orchestrator rules on what it reports.
README.md-120-   - **Stuck builders stop instead of thrashing.** A blocker is posted on
```

Command:
```powershell
git grep -n -C 2 "after-the-fact" -- README.md
```
Output:
```text
README.md-40-approving the spec: in-session, or by commenting `APPROVE` on the tracking
README.md-41-issue from your phone. If you're away, the factory waits about 5 minutes, then
README.md:42:uses the orchestrator's best judgment, records the ruling for after-the-fact
README.md-43-veto, and continues. Irreversible or destructive choices are the carve-out:
README.md-44-silence resolves to the non-destructive path, and `docs/STOP` stays absolute.
--
README.md-94-   issue. A run can carry verbatim pre-approval from your invocation.
README.md-95-   Absent a human: wait about 5 minutes, rule with the orchestrator's best
README.md:96:   judgment, record the ruling for after-the-fact veto, and continue. For
README.md-97-   irreversible or destructive choices, silence resolves to the non-destructive
README.md-98-   path; `docs/STOP` remains absolute. The factory never infers a yes from
```

Command:
```powershell
git grep -ciE "7 days|7-day" -- README.md
```
Exit code: 1
Output:
```text
```

## TD2

Command:
```powershell
git grep -n -C 4 "OWASP" -- DESIGN.md
```
Output:
```text
DESIGN.md-165-  are in-session approval or an `APPROVE` comment on the tracking issue;
DESIGN.md-166-  an invocation can also pre-authorize a run only when the exact
DESIGN.md-167-  pre-authorization text is recorded verbatim. The evidence is the same shape
DESIGN.md-168-  across deployment systems and agent products: GitHub environments auto-fail
DESIGN.md:169:  unapproved runs after 30 days, Azure timeout-rejects approvals, OWASP
DESIGN.md-170-  fail-safe defaults ban inferred allow, and Copilot treats assignment itself
DESIGN.md-171-  as authorization. The 2026-07-03 human directive in
DESIGN.md-172-  [docs/spec/loop-tuning.md](docs/spec/loop-tuning.md) overrides the earlier
DESIGN.md-173-  park-and-poll product behavior: absent a human answer, wait about 5 minutes,
```

Command:
```powershell
git grep -n -C 4 "2026-07-03 human directive" -- DESIGN.md
```
Output:
```text
DESIGN.md-167-  pre-authorization text is recorded verbatim. The evidence is the same shape
DESIGN.md-168-  across deployment systems and agent products: GitHub environments auto-fail
DESIGN.md-169-  unapproved runs after 30 days, Azure timeout-rejects approvals, OWASP
DESIGN.md-170-  fail-safe defaults ban inferred allow, and Copilot treats assignment itself
DESIGN.md:171:  as authorization. The 2026-07-03 human directive in
DESIGN.md-172-  [docs/spec/loop-tuning.md](docs/spec/loop-tuning.md) overrides the earlier
DESIGN.md-173-  park-and-poll product behavior: absent a human answer, wait about 5 minutes,
DESIGN.md-174-  rule with the orchestrator's best judgment, record the ruling for
DESIGN.md-175-  after-the-fact veto, and continue. Carve-out: irreversible or destructive
```

Command:
```powershell
git grep -n -C 3 "twice-observed false" -- DESIGN.md
```
Output:
```text
DESIGN.md-369-  fallback template
DESIGN.md-370-  ([factory-hardening evidence](docs/research/factory-hardening-evidence.md)).
DESIGN.md-371-  Done now means the report's last non-blank line starts with `STATUS:`; report
DESIGN.md:372:  existence alone produced twice-observed false `ALL_DONE` evidence in the
DESIGN.md-373-  run #36 respawn case and the run #43 incremental-write case recorded in
DESIGN.md-374-  [docs/spec/loop-tuning.md](docs/spec/loop-tuning.md).
DESIGN.md-375-- **Hard stops (D11).** the `docs/STOP` kill switch before any wave; irreversible actions;
```

Command:
```powershell
git grep -n -A 7 "Tracking issue #43" -- DESIGN.md
```
Output:
```text
DESIGN.md:199:  Tracking issue #43's 2026-07-03 DIGEST comment, reflected in
DESIGN.md-200-  [docs/spec/loop-tuning.md](docs/spec/loop-tuning.md) and
DESIGN.md-201-  [docs/jobs/status-scripts-rulings.md](docs/jobs/status-scripts-rulings.md),
DESIGN.md-202-  tightened run mechanics: judges dispatch concurrently for every DONE, the
DESIGN.md-203-  ready-issue frontier recomputes on every merge, independent bookkeeping
DESIGN.md-204-  batches into parallel calls, and merges, synthesis, and stress-testing stay
DESIGN.md-205-  serial.
DESIGN.md-206-- **Concurrently scheduled issues share nothing mutable.** Not files,
```

Command:
```powershell
git grep -c "loop-tuning" -- DESIGN.md
```
Output:
```text
DESIGN.md:3
```

## TD3

Command:
```powershell
git grep -n -A 7 "Spec approval" -- CONTEXT.md
```
Output:
```text
CONTEXT.md:51:- **Spec approval** - the one human step: review one spec document, edit or
CONTEXT.md-52-  veto its recorded assumptions, approve in-session or by commenting
CONTEXT.md-53-  `APPROVE` on the tracking issue. Verbatim pre-approval can authorize a run
CONTEXT.md-54-  at invocation; otherwise the factory waits about 5 minutes, rules with the
CONTEXT.md-55-  orchestrator's best judgment, records the ruling for after-the-fact veto,
CONTEXT.md-56-  and continues. Irreversible or destructive silence takes the non-destructive
CONTEXT.md-57-  path; `docs/STOP` remains absolute.
CONTEXT.md-58-- **Check** - a frozen, committed, exact acceptance check
```

Command:
```powershell
git grep -n -A 3 "Watchdog" -- CONTEXT.md
```
Output:
```text
CONTEXT.md:19:- **Watchdog** - a deterministic script that sweeps in-flight jobs and exits
CONTEXT.md-20-  with typed evidence (`ALL_DONE`, `INTEGRATED`, `STALL`, `REPEAT`). It never
CONTEXT.md-21-  kills, nudges, or decides; the orchestrator rules on the evidence. A job is
CONTEXT.md-22-  done only when its report's final non-blank line starts with `STATUS:`.
```

Command:
```powershell
$lines = Get-Content -LiteralPath CONTEXT.md; $end = ($lines | Select-String -Pattern '^## Retired terms').LineNumber; $lines[0..($end - 2)] | Select-String -Pattern '\b(gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag)\b'
```
Output:
```text
```

## TD4

Command:
```powershell
git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md
```
Output:
```text
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/adr/0001-in-session-loop-replaces-external-driver.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/spec/architect-v5.1.md)
DESIGN.md:](docs/research/loop-improvements.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/loop-tuning.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/spec/loop-tuning.md)
DESIGN.md:](docs/jobs/status-scripts-rulings.md)
DESIGN.md:](docs/solutions/worktree-stale-snapshot.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/spec/loop-tuning.md)
DESIGN.md:](docs/research/status-display-evidence.md)
DESIGN.md:](docs/jobs/status-scripts-rulings.md)
DESIGN.md:](docs/research/lesson-store-evidence.md)
DESIGN.md:](docs/research/loop-improvements.md)
DESIGN.md:](docs/research/agent-pipeline-patterns.md)
DESIGN.md:](docs/adr/0001-in-session-loop-replaces-external-driver.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/solutions/subagent-shell-strip-codex-fallback.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/solutions/git-bash-msys-codex-sandbox.md)
DESIGN.md:](docs/solutions/uv-cache-sandbox-redirect.md)
```

Command:
```powershell
$matches = git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md; $targets = $matches | ForEach-Object { if ($_ -match '\]\((docs/[^)#]+)\)') { $Matches[1] } } | Sort-Object -Unique; $targets | ForEach-Object { "$_ => $(Test-Path -LiteralPath $_)" }
```
Output:
```text
docs/adr/0001-in-session-loop-replaces-external-driver.md => True
docs/jobs/status-scripts-rulings.md => True
docs/research/agent-pipeline-patterns.md => True
docs/research/autonomous-software-factory.md => True
docs/research/factory-hardening-evidence.md => True
docs/research/lesson-store-evidence.md => True
docs/research/loop-improvements.md => True
docs/research/status-display-evidence.md => True
docs/solutions/git-bash-msys-codex-sandbox.md => True
docs/solutions/subagent-shell-strip-codex-fallback.md => True
docs/solutions/uv-cache-sandbox-redirect.md => True
docs/solutions/worktree-stale-snapshot.md => True
docs/spec/architect-v5.1.md => True
docs/spec/architect-v5.md => True
docs/spec/loop-tuning.md => True
```

## Final State

Command:
```powershell
git status --short
```
Output:
```text
 M CONTEXT.md
 M DESIGN.md
 M README.md
?? docs/jobs/tuning-docs-01.md
```

STATUS: COMPLETE
