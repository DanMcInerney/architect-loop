# Checkrun: os-validator-checkrun
generated: 2026-07-04T21:45:49.4544413Z  runner: ps1  config: C:/Users/danhm/tools/architect-loop/.architect/checkrun-os-validator.json
check_file: docs/checks/os-validator.md  freeze_sha: 4ebe337a65e0fe616eb4d3310a307c8eba3c8179
Executor: powershell; `uv` uses fresh cache `.architect/tmp/uv-cache-os`.
executor_config: powershell
integrity: check_file_matches_freeze=true head=40f5064ce767c93b9609d31f30a0dfa4c4f52f1f
changed_files: 27 listed below; docs_checks_touched=true
docs/checks/os-checkrun-fix.md
docs/jobs/os-checkrun-fix-01.md
docs/jobs/os-checkrun-fix-checkrun.md
docs/jobs/os-scripts-01.md
docs/jobs/os-scripts-checkrun.md
docs/jobs/os-scripts-rulings.md
docs/jobs/os-validator-01.md
docs/jobs/os-validator-rulings.md
docs/jobs/os-wiring-01.md
docs/jobs/os-wiring-checkrun.md
docs/jobs/os-wiring-rulings.md
docs/spec/orchestrator-scripts.md
skills/architect/SKILL.md
skills/architect/check-runner.ps1
skills/architect/dispatch.md
skills/architect/loop.md
skills/architect/postflight.ps1
skills/architect/postflight.sh
skills/architect/preflight.ps1
skills/architect/preflight.sh
tests/fixtures/checkrun/config-quoted-bash.json
tests/fixtures/checkrun/config-quoted-ps.json
tests/fixtures/checkrun/fixture-checks-quoted-bash.md
tests/fixtures/checkrun/fixture-checks-quoted-ps.md
tests/fixtures/orchscripts/make-fixture.ps1
tests/fixtures/orchscripts/make-fixture.sh
tests/validate_skills.py

## OV1 — validator green end-to-end line 13
$ $env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python tests/validate_skills.py
exit: 0  ms: 679  bytes: 45
OK - 2 skills validated, v4 contracts clean

## OV2 — contracts reference the new artifacts line 17
$ (Select-String -Path tests/validate_skills.py -Pattern 'preflight.ps1').Count
exit: 0  ms: 410  bytes: 3
1

## OV2 — contracts reference the new artifacts line 18
$ (Select-String -Path tests/validate_skills.py -Pattern 'postflight.sh').Count
exit: 0  ms: 401  bytes: 3
1

## OV2 — contracts reference the new artifacts line 19
$ (Select-String -Path tests/validate_skills.py -Pattern 'Preflight and postflight dispatch').Count
exit: 0  ms: 434  bytes: 3
2

## OV3 — syntax line 23
$ $env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('OV3_OK')"
exit: 0  ms: 477  bytes: 8
OV3_OK
