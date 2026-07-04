# jr-validator-01

## PHASE 0

FIRST ACTION:
```text
FOUND docs/checks/jr-validator.md
FOUND skills/architect/check-runner.ps1
FOUND skills/architect/check-runner.sh
GREP skills/architect/dispatch.md:1
FIRST_ACTION_OK
```

Plan:
```text
1. Add check-runner.ps1 and check-runner.sh to tests/validate_skills.py REQUIRED_SIBLINGS["architect"].
2. Add a dispatch contract assertion for skills/architect/dispatch.md:
   - exact section heading ## Check-runner dispatch is present.
   - architect-judge-template and architect-codex-judge-template blocks contain re-run at least one RUN command.
3. Run docs/checks/jr-validator.md V1, V2, V3, and local V4-equivalent restore sequence.
4. Record V5 function/file evidence.
```

Disagreements:
```text
none
```

Checked before finding none:
```text
docs/spec/judge-runner.md: D2 requires check-runner.ps1 and check-runner.sh siblings under skills/architect.
docs/spec/judge-runner.md: D4 requires judge templates to read evidence and re-run at least one RUN command.
docs/spec/judge-runner.md: D5 requires loop wiring; validator slice checks D2/D5 anchors only.
docs/checks/jr-validator.md: V4 is judge-executed; local builder must not leave skills/ mutated.
tests/validate_skills.py: REQUIRED_SIBLINGS centralizes existing sibling checks.
tests/validate_skills.py: errors.append(...) + nonzero main() implements named defects.
skills/architect/dispatch.md: ## Check-runner dispatch exists once.
skills/architect/dispatch.md: both judge template blocks currently contain re-run at least one RUN command.
```

## Source Diff

```diff
diff --git a/tests/validate_skills.py b/tests/validate_skills.py
index 2b4480a..7045a19 100644
--- a/tests/validate_skills.py
+++ b/tests/validate_skills.py
@@ -32,6 +32,8 @@ REQUIRED_SIBLINGS = {
         "watchdog.sh",
         "status.ps1",
         "status.sh",
+        "check-runner.ps1",
+        "check-runner.sh",
         "tracker.md",
     ],
     "architect-research": ["tactics.md"],
@@ -253,6 +255,30 @@ def check_judge_template() -> None:
         errors.append("skills/architect/dispatch.md: C5 template does not forbid slice-specific prose")
 
 
+def check_check_runner_dispatch_contract() -> None:
+    dispatch = SKILLS / "architect" / "dispatch.md"
+    if not dispatch.exists():
+        errors.append("skills/architect/dispatch.md: missing (required for check-runner dispatch contract)")
+        return
+    text = read_text(dispatch)
+    if "## Check-runner dispatch" not in text.splitlines():
+        errors.append("skills/architect/dispatch.md: missing ## Check-runner dispatch")
+    for marker in ("architect-judge-template", "architect-codex-judge-template"):
+        start = f"<!-- {marker}:start -->"
+        end = f"<!-- {marker}:end -->"
+        start_at = text.find(start)
+        end_at = text.find(end, start_at + len(start))
+        if start_at == -1 or end_at == -1:
+            errors.append(f"skills/architect/dispatch.md: missing {marker} marker block")
+            continue
+        block = text[start_at + len(start) : end_at]
+        if "re-run at least one RUN command" not in block:
+            errors.append(
+                "skills/architect/dispatch.md: "
+                f"{marker} missing re-run at least one RUN command"
+            )
+
+
 PADDED_TOOLS = ("Bash", "Read", "PowerShell")
 
 
@@ -482,6 +508,7 @@ def main() -> int:
     check_model_alias_table()
     check_config_example()
     check_judge_template()
+    check_check_runner_dispatch_contract()
     check_agent_definitions()
     check_codex_install_step()
     check_watchdog_contract()
```

## V1

Command:
```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr'; uv run --no-project python tests/validate_skills.py
```

Output:
```text
OK - 2 skills validated, v4 contracts clean
```

## V2

Commands and output:
```text
> (Select-String -Path tests/validate_skills.py -Pattern 'check-runner.ps1').Count
1
> (Select-String -Path tests/validate_skills.py -Pattern 'check-runner.sh').Count
1
> (Select-String -Path tests/validate_skills.py -Pattern 'Check-runner dispatch').Count
3
> (Select-String -Path tests/validate_skills.py -Pattern 're-run at least one RUN command').Count
2
```

## V3

Command:
```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('V3_OK')"
```

Output:
```text
V3_OK
```

## V4

```text
not run by builder
prompt note: frozen check V4 is JUDGE-executed; you do not run it
source evidence for expected nonzero missing-runner failure:
tests/validate_skills.py:35:        "check-runner.ps1",
tests/validate_skills.py:99:def check_siblings(skill_dir: Path) -> None:
tests/validate_skills.py:101:            errors.append(f"{skill_dir.name}: required file {sibling} missing")
```

## V5

```text
tests/validate_skills.py:35:        "check-runner.ps1",
tests/validate_skills.py:36:        "check-runner.sh",
tests/validate_skills.py:99:def check_siblings(skill_dir: Path) -> None:
tests/validate_skills.py:258:def check_check_runner_dispatch_contract() -> None:
tests/validate_skills.py:264:    if "## Check-runner dispatch" not in text.splitlines():
tests/validate_skills.py:265:        errors.append("skills/architect/dispatch.md: missing ## Check-runner dispatch")
tests/validate_skills.py:275:        if "re-run at least one RUN command" not in block:
tests/validate_skills.py:278:                f"{marker} missing re-run at least one RUN command"
```

## Integrity

```text
> git.exe status --porcelain docs/checks skills

> git.exe diff --check -- tests/validate_skills.py docs/jobs/jr-validator-01.md
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
> git.exe status --porcelain
 M tests/validate_skills.py
?? docs/jobs/jr-validator-01.md
```

STATUS: PASS
