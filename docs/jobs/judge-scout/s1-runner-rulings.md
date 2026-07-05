# Post-freeze rulings: judge-scout/s1-runner

RULING 1 (2026-07-05, after first judgment FAIL): the sh runner's match
grading via `case "$stdout_text" in *"$expected"*)` treats glob
metacharacters in the expected substring as patterns; the frozen contract
requires FIXED-substring semantics identical to the ps1 ordinal IndexOf over
whole captured stdout. Fix the sh side to a mechanism where `*`, `?`, `[`
are inert and matching runs over the whole stdout string (e.g. POSIX
quoted-pattern parameter expansion or awk index(); builder's choice, POSIX
sh only, no bashisms). ADD a fixture RUN case whose match expectation
contains glob metacharacters (at least `*` and `?`) that must match only
literally, plus a companion case proving a glob-would-match-but-literal-
does-not input FAILs; wire both into the validator's fixture assertions for
both executors. Everything else in judgment 1 passed; keep it as built.
