# Git Bash/MSYS under the Codex Windows sandbox

**Symptom:** Git for Windows `bash.exe`, `usr/bin/grep.exe`, and `sed.exe`
die at startup in the Codex Windows workspace-write sandbox with
`CreateFileMapping ... Win32 error 5. Terminating.`

**Root cause:** Git Bash uses the MSYS2 runtime, which inherits Cygwin's
startup path for per-user shared memory sections (`CreateFileMappingW`).
Codex on Windows runs commands as dedicated sandbox users with restricted
tokens. The Cygwin/MSYS section ACLs do not match the sandbox token, so
section creation fails with access denied before the program can run.

| Scope | Result |
|---|---|
| PowerShell | works |
| Native `git.exe`, including `git grep` | works |
| Git Bash `bash.exe` | dies with `CreateFileMapping` / `Win32 error 5` |
| Git for Windows `usr/bin/grep.exe`, `sed.exe` | dies the same way |
| Windows outside Codex sandbox | works on this machine |
| POSIX Codex sandboxes | unaffected |

**Rule:** check files should name the platform-native executor primary:
PowerShell plus native `git.exe` subcommands for sandboxed Windows jobs; bash
for POSIX jobs. Recorded substitutions stay explicit.

**Upstream:** [openai/codex#12000](https://github.com/openai/codex/issues/12000)
and [openai/codex#21715](https://github.com/openai/codex/issues/21715).
