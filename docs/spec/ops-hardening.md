# Spec: ops-hardening — script watchdog, durable spec approval, executor truth

Three fixes from the rename-run retro (tracking issue #30's digest), evidence
in `docs/research/factory-hardening-evidence.md`: (1) stall detection moves
from an LLM monitor to a deterministic watchdog script; (2) spec approval
becomes durable and default-deny with an explicit pre-approval fast path;
(3) executor facts and orchestrator shell hygiene get codified.

## Approval record

Pre-approved at invocation, 2026-07-03: "lets do it all. Dig a little deeper
into the git bash though…" following the full plan presented in-session
(watchdog script + LLM-out-of-detection-loop, park-and-poll approval,
mechanical hardening, four-issue run shape). The Git Bash investigation is
folded into the evidence doc and the executor-note wording.

## Goal

- `skills/architect/watchdog.ps1` and `watchdog.sh`: deterministic wave
  watchdogs, installed with the skill, that detect mechanically and never
  decide. The LLM leaves the detection loop on harnesses with background-exit
  notifications.
- Spec approval semantics in `SKILL.md`: two explicit approval forms
  (in-session; `APPROVE` comment on the tracking issue), pre-approval at
  invocation recorded verbatim, park-and-poll when the human is absent,
  bounded 7-day wait then fail-safe stop. Inferred approval is banned.
- `dispatch.md`/`loop.md` monitor sections rewritten around the watchdog;
  LLM monitor retained only as documented fallback for backends without
  background-exit notifications. `.claude/agents/architect-monitor.md`
  deleted (unusable under the D12 6/6 shell-strip evidence; dead surface).
- Executor truth + orchestrator shell hygiene recorded in `dispatch.md` and
  `docs/solutions/`.

## Non-goals

- No change to builder/judge flow, frozen-check mechanics, tiering, or the
  stress-test.
- No new config keys.
- No rewriting of historical run artifacts.

## Interface contract (shared across issues)

**Watchdog config** (orchestrator writes one JSON file per wave):

```json
{
  "sweep_sec": 120,
  "stall_after_min": 10,
  "jobs": [
    { "id": "issue-31", "events_file": "<path>", "report_path": "<path>",
      "worktree": "<path>", "duration_hint_min": 0 }
  ]
}
```

**Watchdog exit contract** (stdout carries raw evidence, one block per job):

| Exit | Line prefix | Meaning |
|---|---|---|
| 0 | `WATCHDOG: ALL_DONE` | every job's report file exists; evidence lists each report path + byte size |
| 2 | `WATCHDOG: INTEGRATED` | a job's worktree/events file vanished — orchestrator merged it mid-sweep |
| 3 | `WATCHDOG: STALL` | no events-file byte growth across two consecutive sweeps beyond `stall_after_min` (+hint) AND no CPU-time delta on command-line-matched processes; evidence: job id, minutes since growth, CPU delta, tail excerpt |
| 4 | `WATCHDOG: REPEAT` | last K(=4) parsed command events identical (OpenHands threshold); evidence: the repeated command + count |

Detection thresholds: repeated-action K=4 per OpenHands' stuck detector;
no-growth grace per GitLab's one-hour-no-output precedent scaled to
`stall_after_min`; duration hints extend the grace, never cap it (no kill
ceilings — human ruling 2026-07-03 stands). The watchdog never kills,
nudges, or judges; exits 2/3/4 are evidence for the orchestrator to rule on.
Process matching is by command-line substring (worktree path), never
ParentProcessId (documented stale/reused, MS Win32_Process docs). File reads
are byte-size based (encoding-agnostic); tail parsing is encoding-aware.

**Approval strings** (SKILL.md + tracking-issue template): approval comment
is exactly `APPROVE`, optionally `APPROVE with edits: <text>`; rejection is
`REJECT <reason>`. Park posts `AWAITING APPROVAL` on the tracking issue.

**Executor note** (dispatch.md): MSYS2/Cygwin-runtime binaries (Git for
Windows `bash.exe`, `usr/bin/grep.exe`, `sed.exe`) fail at startup under the
Codex Windows sandbox (`CreateFileMapping … Win32 error 5` — shared-section
creation denied to the sandbox token). Native binaries (`git.exe`,
PowerShell) are unaffected; POSIX codex sandboxes are unaffected. Check
files therefore name the platform-native executor primary: PowerShell for
sandboxed jobs on Windows, bash on POSIX. Final wording confirmed against
`docs/research/factory-hardening-evidence.md` (canary + researcher).

**Shell hygiene** (dispatch.md, orchestrator-side): absolute paths in every
orchestrator shell command; dispatch/judge blocks written with file tools,
never heredocs; never rely on persisted cwd across commands.

## Scope: four issues

| Issue | Files |
|---|---|
| A `hardening-watchdog` | `skills/architect/watchdog.ps1` (new), `skills/architect/watchdog.sh` (new), `tests/validate_skills.py` |
| B `hardening-dispatch` | `skills/architect/dispatch.md`, `skills/architect/loop.md`, delete `.claude/agents/architect-monitor.md` |
| C `hardening-skill-core` | `skills/architect/SKILL.md` |
| D `hardening-docs` (blocked by A, B, C) | `DESIGN.md`, `README.md`, `CONTEXT.md`, `docs/solutions/git-bash-msys-codex-sandbox.md` (new), `docs/solutions/monitor-per-job-evidence.md` (append only) |

## Assumptions (pre-approved unless vetoed on the tracking issue)

- **A1.** Both watchdog scripts implement the identical contract; each stays
  under ~80 lines; PowerShell 5.1-compatible (no `&&`, no ternary).
- **A2.** `.claude/agents/architect-monitor.md` is deleted, not archived; git
  history is the archive. Validator keeps no reference to it.
- **A3.** The LLM-monitor fallback template (for backends without
  background-exit notifications) lives in `dispatch.md` and carries the
  evidence-required exit rules from `docs/solutions/monitor-per-job-evidence.md`.
- **A4.** Approval park window is 7 days, polled by scheduled wakeups at
  ~20-30 min; `docs/STOP` and `REJECT` end the park immediately.
- **A5.** This run's artifacts use the NEW conventions: checks under
  `docs/checks/`, reports under `docs/jobs/`.
- **A6.** Research evidence commits as
  `docs/research/factory-hardening-evidence.md` before the freeze; issue D
  cites it in DESIGN.md entries.
- **A7.** Tier: builders `codex/tier-down` (gpt-5.5, high) — same
  well-specified-mechanical class as the rename run (4/5 first-judgment
  PASS); judges `codex/best` (xhigh).

## Validation strategy

Per issue: word-boundary greps for contract strings; watchdog functional
tests run sandboxed via PowerShell with tiny thresholds against synthetic
configs (ALL_DONE path and STALL path both exercised). Composite
(orchestrator, post-merge): full validator green; `bash -n watchdog.sh`
(orchestrator's unsandboxed bash); one live `watchdog.ps1` smoke run.

## Preflight evidence

gh 2.96.0 ≥ 2.94.0, auth OK; codex-cli 0.139.0; fresh sandbox canary this
session exercises shell execution inside the codex sandbox (also the Git
Bash diagnostic); backend codex/tier-down per A7.
