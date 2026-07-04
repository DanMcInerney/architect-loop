# Spec: github-chat — live human ↔ orchestrator chat over a GitHub issue

Status: DRAFT, awaiting spec approval. Not decomposed, no checks frozen.
Author: orchestrator session, 2026-07-04, from a design conversation with the
repo owner plus one codex web-research lane (sources at the bottom).
Security is a first-class requirement of this spec, not a hardening pass:
no comment may reach the orchestrator's context, or wake it, unless GitHub's
server-side identity proves the author is an authorized human.

## Problem

While the factory loop runs, the only way to talk to the orchestrator is the
terminal session that launched it. The tracker already carries approvals,
digests, and verdicts, but a human comment on an issue mid-run reaches nobody:
the orchestrator sleeps between events and nothing watches for human input.
After a run finishes and the tracking issue closes, there is no channel at
all. The owner wants to chat with the running orchestrator from github.com —
status questions, rulings, follow-ups, even a new intake — and get replies in
the same thread, without burning orchestrator tokens on polling.

## Goal

One persistent, pinned **"Architect chat"** issue per repo. A deterministic
background watcher polls it; a new authorized comment wakes the sleeping
orchestrator exactly like a watchdog event; the orchestrator treats the
comment with in-session-human authority, replies in-thread, and goes back to
sleep. Zero orchestrator tokens while idle. The channel outlives every run.

## Non-goals

- No webhooks, no local HTTP receiver, no smee relay. `gh webhook forward` is
  documented test-only, single-forwarder [S10]; polling one issue at 60s is
  ~60 of 5,000 req/hr [S2] with zero extra infrastructure.
- No always-on daemon. The responder is whichever orchestrator session is
  alive. A scheduled headless `claude -p` one-shot responder (grounds from
  tracker+git, answers, exits) is a recorded v2 escape hatch, not this spec.
- No separate bot account. Same-account operation (owner comments and `gh`
  posts from the same profile) is fully handled by D4/D5. A bot account
  remains a future option for notification ergonomics only.
- No chat in markdown tracker mode. There is no remote comment surface;
  github mode only. Markdown-mode preflight simply skips the watcher.

## Design

### D1. Channel: one pinned chat issue, decoupled from run lifecycle

First github-mode run creates (or finds) an open issue titled
`Architect chat`, pins it, and records its number in `.architect/`
state. It is never closed by the loop. Tracking issues and sub-issues keep
their existing lifecycle. Rationale: the tracking issue closes at finish,
and chat must survive the run; a pinned open issue is findable and does not
read as completed work during the next run's grounding.

### D2. Watcher: deterministic sibling of the watchdog

`skills/architect/chat.ps1` / `chat.sh`, launched with the same
background-process-whose-typed-exit-wakes-the-orchestrator primitive as
`watchdog.ps1`. Config JSON (Interface contract below) carries repo, issue
number, cursor, allowlist, sentinel, poll seconds. Loop every ~60s:

- `gh api --method GET repos/{o}/{r}/issues/{n}/comments -f per_page=100`
  (`--method GET` is mandatory: `gh api` silently switches to POST when
  fields are supplied [S4]). `since=` may trim bandwidth but is
  `updated_at`-semantics [S1] and MUST NOT be the correctness mechanism.
- Filter, in order: comment id > cursor; body does not contain the
  sentinel; author passes the security gate (Security model, SEC-1/SEC-2).
- On any surviving comment: print `CHAT: MESSAGE` plus one JSON line per
  comment `{id, user_id, user_login, author_association, created_at, body}`,
  exit 0. The exit wakes the orchestrator.
- On repeated `gh` failure (3 consecutive): print `CHAT: ERROR <last stderr
  line>`, exit 5. Auth expiry surfaces; no silent retry-forever.

### D3. Fourth wake event in the factory loop

`loop.md` step 3 gains **Chat MESSAGE**: the orchestrator reads the payload
(the new comment bodies only — the token cost of a wake is the comments
themselves) and treats it exactly as an in-session human message. Status
request → run the status script, reply with its verbatim output in a fenced
block. Ruling → existing rulings-file machinery. Scope growth, destructive
asks, STOP → existing hard stops unchanged, `docs/STOP` absolute.

### D4. Reply protocol

Reply via `gh issue comment <n> --body-file -`. Every orchestrator-authored
comment on the chat issue embeds the invisible HTML sentinel
`<!-- architect-orchestrator -->` (a visible `**[orchestrator]**` prefix is
allowed for readability but carries no meaning). Then relaunch the watcher.

### D5. Cursor: last processed HUMAN comment id

The cursor advances to the highest human comment id processed — never to the
orchestrator's own reply id. A human comment posted concurrently with a
reply can carry a lower id than the reply; a cursor set past the reply would
silently drop it. Sentinel excludes the orchestrator's replies; the cursor
only dedupes. Consequence: edits to old comments are invisible by design
(same id, dropped) — post a new comment. Cursor persists in `.architect/`
state across runs and sessions.

### D6. Lifecycle: the watcher outlives the run

At finish, after the digest, the orchestrator relaunches the watcher and
sleeps as an idle orchestrator instead of stopping it. Post-run chat can ask
about the run, request follow-ups, or start a new intake (spec approval by
`APPROVE` comment works from the same thread). If the session dies, the
issue accumulates comments; the next `/architect` session's grounding step
checks the chat issue for comments past the cursor and answers them first.
Tracker + git remain the memory; the session is disposable.

## Security model (paramount)

Threat: anyone with a GitHub account can comment on a public repo's issues.
A comment is an instruction channel into an agent that edits code, so
impersonation or injection here is remote prompt-injection into the factory.
The load-bearing property: **authorization is decided inside the
deterministic script, on GitHub's server-side identity fields, before any
byte of comment body reaches model context or wakes the loop.**

- **SEC-1 — identity by immutable numeric user id.** The allowlist is
  numeric `user.id` values, never logins. Logins are renameable and a
  released login can be re-registered by an attacker; ids are permanent.
  Default allowlist: the repo owner's id, resolved at watcher start via
  `gh api repos/{o}/{r} -q .owner.id`. If the owner is an Organization, the
  watcher refuses to start and the orchestrator hard-stops for an explicit
  human-provided id allowlist — org membership is never implicitly trusted.
- **SEC-2 — second factor: `author_association`.** Surviving comments must
  also carry `author_association` of `OWNER` (or `MEMBER`/`COLLABORATOR`
  only when that id is explicitly allowlisted). This field is computed
  server-side by GitHub and cannot be set by the commenter [S1].
- **SEC-3 — unauthorized comments are inert.** They fail SEC-1 in the
  script and are dropped: they never wake the orchestrator, never enter
  model context, and cost zero tokens. Comment spam is not a DoS on the
  loop. The watcher MAY note `dropped=<n>` in its eventual wake line so
  humans learn of probing, but bodies of dropped comments are never printed.
- **SEC-4 — sentinel forgery is harmless by construction.** An attacker who
  includes `<!-- architect-orchestrator -->` only silences their own
  comment, which SEC-1 already dropped. An authorized human who pastes it
  accidentally silences themselves — visible in-thread, recoverable by
  re-commenting. The sentinel is a self-filter, never an authorization
  signal.
- **SEC-5 — authority ceiling.** An authorized comment gets exactly
  in-session-human authority, no more: hard stops, scope rails, and
  `docs/STOP` apply unchanged. Spec approval from the chat thread requires
  the same exact `APPROVE` forms as the tracking issue. Irreversible or
  destructive asks arriving by chat still resolve through the existing
  hard-stop path — chat never becomes a fast lane around the rails.
- **SEC-6 — the channel is public; replies follow tracker discipline.** On
  a public repo the thread is world-readable: no secrets, tokens, or
  private paths in replies, same as every existing tracker surface. The
  orchestrator passes comment bodies around as data (JSON), and only
  authorized bodies exist past the script boundary.
- **SEC-7 — residual risk, stated.** A compromised owner GitHub account is
  equivalent to a compromised terminal; the mitigation is account hygiene
  (2FA), SEC-5's ceiling, and the public audit trail every instruction
  leaves in the thread. This spec makes impersonation require GitHub
  authentication as the owner — it cannot make owner-authenticated input
  untrusted without killing the feature.

## Interface contract

Watcher config JSON (written by the orchestrator per launch):

```json
{
  "repo": "owner/name",
  "issue": 62,
  "cursor_comment_id": 3141592653,
  "allow_user_ids": [1234567],
  "allow_associations": ["OWNER"],
  "sentinel": "<!-- architect-orchestrator -->",
  "poll_sec": 60
}
```

Typed exits: `0` = `CHAT: MESSAGE` + JSON comment lines; `5` = `CHAT: ERROR
<evidence>`. No other exit is meaningful. The watcher never posts, edits,
closes, or reacts — read-only against the API except the initial owner-id
resolution.

## Assumptions

- A1. Same-account operation (owner == `gh` identity) is the default and is
  correct under D4/D5; a bot account is not required.
- A2. 60s polling latency is acceptable for chat; nobody needs sub-minute.
- A3. The chat issue is created unpinned if pinning fails (pin needs
  maintainer permission the owner has anyway); pinning is best-effort UX.
- A4. Comments-on-closed-issues is NOT used as a channel; the chat issue
  stays open. If a human comments on a closed run issue, nothing listens —
  grounding reconciliation may notice it, but no guarantee is made.

## Validation strategy (sketch, for decomposition)

- Script-level: fixture JSON of comment arrays (unauthorized author, forged
  sentinel, edited old comment, concurrent-id race, org owner) → expected
  filter output and typed exits, runnable without network.
- Live canary: post an authorized comment and an unauthorized-account
  comment (or simulate via fixture when no second account exists) against a
  scratch issue; assert only the authorized one produces `CHAT: MESSAGE`.
- Loop-level: frozen check that `loop.md` step 3 lists the Chat MESSAGE
  event and that finish relaunches the watcher.

## Rejected alternatives

- Tracking issue as channel — dies with the run (the motivating defect).
- GitHub Actions `@claude` / OpenHands / Sweep pattern — fresh stateless
  run per comment, no orchestrator context [S6][S7][S8]; kept only as the
  v2 headless-responder idea, explicitly out of scope here.
- Webhooks (`gh webhook forward`, smee) — test-scoped, single forwarder,
  extra moving parts on a machine with no public endpoint [S10][S11].
- ETag/304 conditional polling — valid and rate-limit-free [S3] but
  unnecessary complexity at 60 req/hr; may be added later without design
  change.
- LLM monitor as the poller — burns tokens to detect what a shell loop
  detects for free.

## Sources

- [S1] https://docs.github.com/en/rest/issues/comments?apiVersion=2022-11-28#list-issue-comments
- [S2] https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28
- [S3] https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api?apiVersion=2022-11-28
- [S4] https://cli.github.com/manual/gh_api
- [S6] https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md
- [S7] https://docs.openhands.dev/openhands/usage/run-openhands/github-action
- [S8] https://github.com/sweepai/sweep/blob/a8b8b67bda4f89faac9314d34e7c7d5a64f76046/docs/pages/getting-started.md
- [S10] https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/using-the-github-cli-to-forward-webhooks-for-testing
- [S11] https://smee.io/
