# Factory-hardening evidence (watchdog, approval gates, Git Bash root cause)

Research handoff, 2026-07-03. Three read-only researchers (codex gpt-5.5
high, live web search, ≤15 searches each) plus one local sandbox canary;
orchestrator verified load-bearing claims. Feeds `docs/spec/ops-hardening.md`.

## 1. Stall detection: the field separates mechanical detection from reasoning

- CI systems detect stalls with code, not models: GitLab drops any job
  "without an output for one hour... regardless of the timeout"
  (docs.gitlab.com/ci/pipelines/settings, accessed 2026-07-03); GitHub
  Actions and Buildkite use wall-clock `timeout-minutes` per job/step.
- Heartbeats are the daemon-world standard: systemd `WatchdogSec=` +
  `sd_notify("WATCHDOG=1")`; late pings → SIGABRT (man systemd.service).
  Kubernetes liveness is a probe, not a watcher process.
- Agent frameworks detect repetition with code: OpenHands' stuck detector
  fires on "same action produces the same observation repeatedly (4+
  times)", repeated errors 3+ (docs.openhands.dev/sdk/guides/agent-stuck-detector)
  — with a documented false positive where intentional 5-minute polling
  produced "4 identical action-observation pairs" and a wrong "Agent stuck
  in loop" (OpenHands/software-agent-sdk#762, 2025-11). Detection
  thresholds are code; the *ruling* needs context.
- Gas Town states the split directly: the Go daemon "can check 'is session
  alive?' but not 'is agent stuck?'" — the latter "requires reasoning" —
  and its mechanical recovery paths "do NOT need Claude sessions"
  (docs.gastownhall.ai/design/watchdog-chain, dog-pool-architecture,
  accessed 2026-07-03).
- Windows mechanics for a script watchdog: match processes by
  `Win32_Process.CommandLine`, never `ParentProcessId` (Microsoft: "may
  incorrectly refer to a process that reuses a process identifier");
  activity via `Process.TotalProcessorTime` deltas; Windows PowerShell `>`
  writes UTF-16LE, so tail parsing must be encoding-aware
  (learn.microsoft.com Win32_Process / TotalProcessorTime /
  about_Character_Encoding).
- Local run evidence (rename run #30, 2026-07-03): LLM monitor at low
  effort produced 2 false positives and 0 true detections across 3
  dispatches (~50k tokens each); every completion event was delivered by
  the harness's background-exit notification.

**Design consequence:** detection becomes a deterministic script
(`watchdog.ps1`/`.sh`) with typed evidence-bearing exits
(ALL_DONE/INTEGRATED/STALL/REPEAT); the orchestrator supplies the
reasoning. The LLM monitor survives only as a fallback for backends with no
background-exit notifications, carrying the per-job-evidence exit rules
(`docs/solutions/monitor-per-job-evidence.md`).

## 2. Approval gates: park by default; pre-authorization is a trigger, not an inference

- GitHub environments required reviewers: runs wait in "Waiting" status; "if
  not approved within 30 days, it will automatically fail"; approval via
  web, mobile (push notifications), or REST (`state: approved|rejected`)
  (docs.github.com deployments, accessed 2026-07-03).
- Azure classic release approvals: "If no approval is granted within the
  Timeout period, the deployment is rejected"; the ManualValidation task
  lets you configure timeout response "reject or resume". AWS Step
  Functions parks on a task token up to one year, with heartbeat timeouts.
  GitLab manual jobs park forever (open issue: "no timeout to fail it").
- Security norm: OWASP fail-safe defaults — "unless an entity is given
  explicit access... it should be denied access... by default".
- Agent products treat the *trigger itself* as authorization: assigning an
  issue to Copilot starts it; OpenHands starts on a `fix-me` label or
  `@openhands-agent` comment; `@claude` / `@codex review` mentions.
  NOT FOUND anywhere: a system that proceeds because the human expressed
  approval earlier in an unrelated exchange.

**Design consequence:** approval has exactly two explicit forms —
in-session, or an `APPROVE` comment on the tracking issue (phone-friendly,
GH-mobile precedent) — plus a pre-approval fast path recorded verbatim from
the invocation (Copilot assign-is-authorization precedent). Absent human →
park with scheduled polling, bounded at 7 days, then fail-safe stop
(GH-style). Inferred approval is banned (OWASP).

## 3. Git Bash death under the Codex sandbox: root cause, scope, upstream status

- **Mechanism:** Cygwin's runtime creates named per-user shared-memory
  sections at startup (`memory_init()` → `CreateFileMappingW`, fatal string
  "CreateFileMapping %W, %E. Terminating." — cygwin `winsup/cygwin/mm/shared.cc`).
  MSYS2 "mostly just means Cygwin" (msys2.org, 2025-02-14). Git for
  Windows' `bash.exe`/`usr/bin/grep.exe`/`sed.exe` ride that runtime.
- **The sandbox side:** Codex's Windows sandbox runs commands as dedicated
  local users (`CodexSandboxOffline`/`CodexSandboxOnline`) with restricted
  tokens and ACLs (OpenAI, "Building a safe, effective sandbox to enable
  Codex on Windows", 2026-05-13). The Cygwin SID-named section objects and
  their ACLs don't line up across users/restricted tokens → Win32 error 5
  (ERROR_ACCESS_DENIED) at startup. Same failure class documented on
  Cygwin's lists since 2003 (ACL/DACL mismatch threads) and in Cursor's
  sandbox (forum.cursor.com, 2026-02-05).
- **Known upstream:** openai/codex#12000 (2026-02-17, Git for Windows
  `sh.exe`, "MSYS2 shared memory usage" in "sandboxed context") and
  openai/codex#21715 (2026-05-08, "All commands to be run in bash fail"
  under Windows workspace-write).
- **Scope (local canary, 2026-07-03, workspace-write sandbox):** native
  `git.exe` works (`git --version`, `git grep` both fine); `bash.exe` (both
  install paths) and `usr/bin/grep.exe` all die with the identical error.
  Outside the sandbox, Git Bash works normally on this machine.
- **Cross-platform:** macOS (Seatbelt) and Linux (Landlock/seccomp) codex
  sandboxes run native shells; NOT FOUND: any equivalent failure there.

**Design consequence:** this is a Codex-Windows-sandbox × Cygwin-runtime
interaction, not a Windows or Git Bash defect, and POSIX platforms are
unaffected. Check files name the platform-native executor primary for
sandboxed jobs — PowerShell (+ native `git.exe` subcommands) on Windows,
bash on POSIX — and keep the recorded-substitution rule for everything else.
