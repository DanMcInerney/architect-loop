> Part A source for slice `v3-loop`, committed verbatim (header added) from
> `C:\tmp\architect-skill-stall-prevention-plan.md`. Adopted AS AMENDED by
> `v3-loop.md` §4.4: graduated per-command timeout ceilings declared in the
> spec replace this file's blanket 600s cap. Where the two conflict,
> `v3-loop.md` wins.

# Architect skill: builder-stall root cause and prevention plan

Incident: slice `skill-delivery-capability-fix`, BenchPair repo, 2026-07-01.
Builder (codex exec, gpt-5.5 xhigh, workspace-write sandbox) stalled ~90
minutes during gate verification. Rescued same-day; lane completed after
resume. This plan targets `~/.claude/skills/architect/` (SKILL.md,
dispatch.md) so this class of stall cannot recur.

## 1. Timeline (all times local, from the run's --json event stream)

| time | event |
| --- | --- |
| 19:34 | Dispatch. Builder grounds, edits 6 files (all in-bounds) in ~10 min. |
| 19:44 | Builder launches gate runs G2/G3/G4 **in parallel**, each with `--basetemp C:\tmp\...` and `-o cache_dir=C:\tmp\...`. Event stream freezes. |
| 19:44–21:13 | Six orphaned python processes; three burn ~2,520s CPU each (~46% of a core, continuously). Codex waits. |
| 21:13 | Architect notices (only because the human asked). Stall confirmed: no file growth 89 min + `in_progress` command items. |
| 21:14 | Rescue step 1: kill the six pytest children. Codex wakes instantly. |
| 21:15 | Builder retries **with `C:\tmp` again** (new suffix). New child hot-spins within ~2 min. |
| 21:17 | Rescue step 2: kill retry children + the codex process (same-hang re-entry). |
| 21:19 | Rescue step 3: `codex exec ... resume <thread-id>` with a rescue block: exact root cause, in-workspace basetemp, sequential gates, 600s timeouts. |
| ~21:45 | Lane completes: report written, sandbox-runnable gates pass, STATUS line present, no out-of-bounds writes. |

## 2. Root cause chain

**L1 — Builder path choice (proximate).** The builder pointed pytest's
`--basetemp`/`cache_dir` at `C:\tmp`, outside the sandbox's writable roots.
The dispatch block suggested an in-workspace basetemp — but only as a
parenthetical example ("route around it (e.g. --basetemp inside the
workspace)"). The parent lane's report tabulated *failed* `C:\tmp` attempts,
which read as precedent. Suggestion lost to pattern-matching.

**L2 — Sandbox failure mode (enabling).** Under the codex Windows
workspace-write sandbox, out-of-root filesystem operations do not reliably
fail fast. Verified signature here: pytest ran to `[100%]` (`E.EEEEE` —
tmp-fixture errors), then the process spun. All three unrelated test files
burned an identical ~2,520s CPU, placing the spin in a common layer
(sandbox I/O interception or session teardown), not in test code. pytest's
own retry loops are bounded (verified: `make_numbered_dir` = 10 tries;
cleanup candidates loop is finite), so a plain `PermissionError` cannot
explain the spin — this is the same failure family as the already-documented
`asyncio.create_subprocess_exec` sandbox hangs. Note the contrast: the
*parent* slice's identical `C:\tmp` attempt failed instantly with
`PermissionError` — the failure mode is nondeterministic, so "it errored
fast last time" is not a safety argument.

**L3 — Parallel gate execution (multiplier).** The builder launched three
test invocations concurrently. Three stuck processes instead of one, and
codex's turn blocked on all of them.

**L4 — No effective timeout ceiling.** The observed command timeout was
5,502,464 ms (~92 min). The dispatch block said "give every potentially
long command an explicit timeout" but set no ceiling, so one bad command
cost 92 minutes, and the retry would have cost 92 more.

**L5 — No proactive architect monitoring (detection gap).** The skill's
stall rule ("15+ min silent on an in-flight command") is sound but only
fires "whenever you return to a running lane." Nothing schedules a return.
Detection happened at minute 89 because the human happened to ask.

## 3. Skill changes

### 3.1 dispatch.md — extend "Known sandbox hang sources" (L2)

Add, alongside the asyncio entry:

> Out-of-workspace temp paths (`C:\tmp`, `$env:TEMP`, pytest
> `--basetemp`/`-o cache_dir` outside the repo) under workspace-write:
> sometimes instant `PermissionError`, sometimes a hot spin *after* tests
> complete (verified: uniform ~46%-core burn across unrelated pytest runs,
> 2026-07-01). Treat any out-of-root write path as a hang source, not an
> error source. Prescribe `--basetemp .architect/tmp/<gate-id>
> -p no:cacheprovider` — inside the workspace, gitignored.

### 3.2 dispatch.md builder-block template — add a SANDBOX EXECUTION POLICY paragraph to PHASE 2 (L1, L3, L4)

Exact text to add:

> All temp, basetemp, and cache paths MUST be inside the workspace
> (`.architect/tmp/<purpose>`); never the system temp, never `C:\tmp`.
> Run test/gate commands SEQUENTIALLY — never two test invocations in
> flight at once. Give every command an explicit timeout of at most 600
> seconds. If a command times out or errors on filesystem access ONCE,
> that path is environmental: record the exact failure and route around
> it — never retry the same path a second time.

Rationale for template placement: rules embedded in the per-lane block are
the only ones proven to reach the builder; the "(e.g. ...)" phrasing
demonstrably did not bind.

### 3.3 Dispatch blocks prescribe exact gate invocations, not examples (L1)

Spec-writing rule for the architect (SKILL.md step 4, Tool guidance
bullet): when a known-bad pattern exists, name it as forbidden with its
evidence ("never `C:\tmp` — it spins; see lane report X") and give the
*exact* command form to use, flags included. Builders pattern-match on
lane-report history; failed attempts recorded in prior lane reports read
as precedent unless explicitly marked poisoned.

### 3.4 SKILL.md step 5 — scheduled liveness checks (L5)

Replace "Whenever you return to a running lane, check liveness" with a
mandatory loop: after dispatch, schedule a liveness check every 15–20
minutes for the life of the run (harness-appropriate mechanism: Monitor
until-loop, ScheduleWakeup, or equivalent). Each check: has the `--json`
output file grown? If not, and the last event is an `in_progress`
command_execution, enter the rescue ladder immediately. Detection latency
budget: one interval, not "whenever."

### 3.5 dispatch.md — codify the rescue ladder that worked (L5)

Currently the doc says "kill the stuck child, not the run" and stops.
Codify all three rungs with the verified mechanics:

1. **Kill stuck children** (narrowest). On Windows the direct child list
   can lie: wrappers die while grandchildren hold the pipes. Search
   system-wide for processes matching the command's signature (path
   fragments, e.g. the basetemp name), not just the codex process tree.
   Expect codex to wake within seconds of the pipes closing.
2. **Same hang re-entered → kill the run, resume the thread.**
   `codex exec [flags] resume <thread-id> - < rescue-block.md`.
   Flag order gotcha (verified, codex 0.139): global flags go BEFORE the
   `resume` subcommand; `-C` after `resume` is rejected. The thread id is
   in the first `thread.started` event. Resume preserves the builder's
   full context — this rescued ~2h of completed build work.
3. **Resume fails or hangs again → discard the lane and re-dispatch**
   (existing hard rule 7).

Add a rescue-block template next to the builder-block template. Required
elements (all present in the block that worked): what was observed from
outside the sandbox; the verified root cause; explicit "do not use X
again"; confirmation that working-tree edits survived ("do not redo
them"); the exact prescribed command form; the reminder that
architect re-runs gates at judgment; restated boundaries + STATUS
requirement.

### 3.6 dispatch.md — investigate a hard timeout cap at dispatch time (L4)

Check whether codex 0.139+ exposes a config override capping per-command
duration (candidate: a `-c` tool-timeout key — verify against the codex
config reference before relying on it; do not assert from memory). If it
exists, add it to the canonical dispatch command so no builder command can
exceed ~10 minutes regardless of block compliance. If it does not exist,
the 3.2 block text remains the only control — note that explicitly so the
gap is a known, owned risk.

## 4. Verification

- Next dispatch in this repo: confirm the builder block contains the
  SANDBOX EXECUTION POLICY paragraph and the gate file prescribes exact
  in-workspace basetemp invocations.
- Confirm a liveness monitor exists before the dispatching session ends
  (its absence is now a procedure violation, same class as skipping
  post-flight).
- Success criterion: worst-case stall detection latency ≤ 20 min (one
  interval), and no gate command may consume more than 600s before the
  builder must route around it.

## 5. Out of scope

- Fixing the codex sandbox's non-fail-fast denial behavior (upstream).
- Repo-level changes (BenchPair's gate docs already carry the
  architect-runs-gates-outside-sandbox note; the in-workspace basetemp
  convention lands in future gate files via 3.3).
