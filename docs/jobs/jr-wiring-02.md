# PHASE 0

```text
COMMAND: git rev-parse HEAD
fb7414dd83e08f1e251338c1dd4ca0f853998cf2
EXIT: 0

COMMAND: git rev-parse job/jr-wiring-01
fb7414dd83e08f1e251338c1dd4ca0f853998cf2
EXIT: 0

COMMAND: Test-Path -LiteralPath docs/checks/jr-wiring.md
True
EXIT: 0

COMMAND: $i=0; Get-Content -LiteralPath docs/jobs/jr-wiring-rulings.md | ForEach-Object { $i++; if ($i -ge 11 -and $i -le 17) { "{0}:{1}" -f $i, $_ } }
11:
12:Respawn fix contract (jr-wiring-02): amend that intro sentence so the
13:enumerated replace-list includes the checkrun evidence path placeholder.
14:Audit the C5 judge template intro for the same enumeration mismatch; its
15:generic "replacing placeholders" wording is acceptable unchanged. No other
16:edits. Boundaries and frozen checks unchanged; prior work stands at job
17:branch commit 6971312.
EXIT: 0
```

```text
MIRROR: ORCHESTRATOR
DISAGREEMENTS: none

AUDIT: skills/architect/dispatch.md:92
The orchestrator must send this template as-is except for replacing placeholders. It must not add slice-specific prose, encouragement, summaries, or interpretation.

AUDIT: skills/architect/dispatch.md:124
The orchestrator must send this template as-is except for replacing the check file path, freeze SHA, branch, worktree note, and checkrun evidence file path. It must not add slice-specific prose, encouragement, summaries, or interpretation.
```

# Evidence

````text
COMMAND: git diff -- skills/architect/dispatch.md
diff --git a/skills/architect/dispatch.md b/skills/architect/dispatch.md
index 8c47aa8..42e3a50 100644
--- a/skills/architect/dispatch.md
+++ b/skills/architect/dispatch.md
@@ -121,7 +121,7 @@ Verdict format:
 
 ## Codex judge delegation template
 
-The orchestrator must send this template as-is except for replacing the check file path, freeze SHA, branch, and worktree note. It must not add slice-specific prose, encouragement, summaries, or interpretation.
+The orchestrator must send this template as-is except for replacing the check file path, freeze SHA, branch, worktree note, and checkrun evidence file path. It must not add slice-specific prose, encouragement, summaries, or interpretation.
 
 <!-- architect-codex-judge-template:start -->
 ```text
EXIT: 0

COMMAND: git diff -- docs/checks
<no output>
EXIT: 0
````

# W1

```text
COMMAND: git grep -c "## Check-runner dispatch" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c -- "- RUN:" skills/architect/dispatch.md
skills/architect/dispatch.md:3
EXIT: 0

COMMAND: git grep -c "max_output_lines" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "CHECKRUN: ERROR" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
```

# W2

```text
COMMAND: git grep -c "checkrun" -- skills/architect/dispatch.md
skills/architect/dispatch.md:7
EXIT: 0

COMMAND: git grep -c "re-run at least one RUN command" -- skills/architect/dispatch.md
skills/architect/dispatch.md:2
EXIT: 0

COMMAND: git grep -c "Source: evidence-file" -- skills/architect/dispatch.md
skills/architect/dispatch.md:2
EXIT: 0

COMMAND: git grep -c "never FAIL" -- skills/architect/dispatch.md
skills/architect/dispatch.md:2
EXIT: 0

COMMAND: git grep -c "evidence_out" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "architect-judge-template:start" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0

COMMAND: git grep -c "architect-codex-judge-template:start" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
```

# W3

```text
COMMAND: git grep -c "MUST use" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
EXIT: 0
```

# W4

```text
COMMAND: git grep -c "check-runner" -- skills/architect/loop.md
skills/architect/loop.md:2
EXIT: 0

COMMAND: git grep -c "checkrun" -- skills/architect/loop.md
skills/architect/loop.md:2
EXIT: 0

COMMAND: git grep -c "check-runner" -- skills/architect/SKILL.md
skills/architect/SKILL.md:2
EXIT: 0
```

# W5

```text
COMMAND: (Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() }).Count
208
EXIT: 0

COMMAND: (Get-Content skills/architect/loop.md | Where-Object { $_.Trim() }).Count
100
EXIT: 0

COMMAND: (Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() }).Count
492
EXIT: 0
```

STATUS: COMPLETE
