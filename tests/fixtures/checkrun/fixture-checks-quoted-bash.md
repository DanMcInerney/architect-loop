# Fixture Checks: Failing Bash

Executor: bash

## Fixture

CHECKRUN_BASH_PRESENT_MARKER

- RUN: `printf 'quoted marker\n'` -> exit:0 match:"quoted marker"
- RUN: `git grep -F -q "CHECKRUN_BASH_PRESENT_MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-bash.md` -> exit:1
- RUN: `printf 'glob candidate: axxbZc\n'` -> exit:0 match:"a*b?c"
