# grep-qif-sigabrt

## Symptom

A frozen-check RUN command combining `-q`, `-i`, and `-F` in one `grep`
invocation (`grep -qiF ...` or the recursive `grep -qriF ...`) aborts
instead of returning a normal match/no-match exit code:

```text
$ echo "hello world" | grep -qiF "HELLO"; echo "exit:$?"
/usr/bin/bash: line 1:  5294 Done                    echo "hello world"
      5295 Aborted                 | grep -qiF "HELLO"
exit:134
```

```text
$ grep -qriF "HELLO" some/dir; echo "exit:$?"
/usr/bin/bash: line 1:  5303 Aborted                 grep -qriF "HELLO" some/dir
exit:134
```

Exit 134 is SIGABRT, not a graded expectation mismatch — a check authored
with this pattern crashes the shell instead of producing exit 0/1, which a
frozen-check RUN item's `-> exit:<n>` grammar cannot represent as a normal
pass/fail.

This surfaced during the skill-library run's pre-freeze adversarial review
(`/adversarial-review` decomposition stress test, issue #109/s6): the
reviewer executes every draft `- RUN:` command against the current tree
before authorizing the freeze, and any draft check authored with this
`-i`+`-F` combination aborted rather than exiting 0/1/2 as a check-runner
RUN item expects. No shipped frozen check under `docs/checks/skill-library/`
uses the combination today — every one uses `-qi` alone or `-qF` alone
(verified: `grep -rn "grep -qiF\|grep -qriF" docs/checks/skill-library/`
returns no matches), consistent with the combination having been caught and
avoided before freeze rather than shipped.

## Root Cause

GNU grep 3.0 (the version shipped with this machine's Git Bash — verified
`grep --version` reports `grep (GNU grep) 3.0`) has a defect where
combining the `-i` (ignore-case) and `-F` (fixed-string) options under `-q`
(quiet) triggers an internal abort rather than a clean non-match return.
`-i` and `-F` each work fine alone; only the combination aborts.

## What Did Not Work

- Writing a frozen-check RUN item as `grep -qiF "<substring>" <file>` to
  get a fast case-insensitive fixed-string match in one flag bundle.
- Writing the recursive form `grep -qriF "<substring>" <dir>` for the same
  reason.
- Treating the resulting exit 134 as if it were a legitimate "no match"
  (exit 1) when grading a RUN item — it is a crash, not a result.

## Route Around

- Never combine `-i` and `-F` in the same `grep` invocation on this
  toolchain (GNU grep 3.0, Git Bash). Use `-qi` alone (case-insensitive,
  basic/extended regex) when case-insensitivity matters more than avoiding
  regex metacharacter interpretation, or `-qF` alone (fixed-string,
  case-sensitive) when exact substring matching matters more than case.
  Verified working: `echo "hello world" | grep -qi "HELLO"` → exit 0;
  `echo "hello world" | grep -qF "hello"` → exit 0.
- If both case-insensitivity and fixed-string matching are required, escape
  the pattern for regex and use `-qi` instead of reaching for `-F`, or
  lower-case both sides and compare with `-qF`.
- When authoring frozen-check RUN items, run the draft command against the
  real tree before freezing — the same execution discipline
  `/adversarial-review`'s decomposition stress test already performs — so a
  crashing command is caught pre-freeze, not discovered at judgment time.
