---
name: no-sleep-to-wait
description: Never use `sleep` to wait for a command, process, or service. Use the tool's own blocking/wait flag, or just check -- most waits are not needed at all.
scope: bash
condition: '(^|\s)sleep\s+[0-9]'
interruptMode: never
---

# Don't Sleep to Wait

```
IF YOU ARE TYPING `sleep`, THE WAIT IS EITHER UNNECESSARY OR THE WRONG MECHANISM.
```

`sleep N` guesses. Too short and you read incomplete state and act on it; too
long and you burn wall-clock on every run. Either way the shell already has a
primitive that waits for the actual condition.

## Instead

| Waiting for | Use |
|---|---|
| A command you started | Don't background it -- run it in the foreground, or `wait <pid>` |
| An HTTP endpoint | `curl --retry 5 --retry-connrefused --retry-delay 1` |
| A port | `nc -z host port` in a bounded retry loop, or the service's readiness command |
| A systemd unit | `systemctl start` (already blocks), `systemctl is-active --wait` |
| A container | `docker run --wait`, `docker compose up --wait`, `--health-cmd` + `docker wait` |
| Kubernetes | `kubectl wait --for=condition=... --timeout=...`, `kubectl rollout status` |
| A GitHub Actions run | `gh run watch <run-id> --exit-status` (blocks, exits nonzero on failure) |
| A PR's checks | `gh pr checks <pr> --watch --fail-fast` |
| A file to appear | Bounded poll loop with a timeout and a nonzero exit on expiry |
| A test's async work | Poll the condition (see the `condition-based-waiting` skill) -- never `time.sleep` |

If nothing in the environment can express the condition, write a bounded poll:
check, short interval, hard timeout, nonzero exit when it expires. That is a
retry loop, not a sleep -- it exits as soon as the condition holds and it fails
loudly when it never does.

## First, ask whether you need to wait

Most `sleep` calls exist because a command was backgrounded that didn't need to
be. Run it in the foreground and the wait disappears.

## Legitimate uses

Not every `sleep` is a wait-for-completion. These are fine:
- The interval inside a bounded poll or retry loop.
- Rate limiting / backoff between deliberate requests.
- Reproducing a timing bug on purpose.

## The test

1. Am I sleeping to let something finish? Then find its wait mechanism.
2. Does the thing I started need to be in the background at all?
3. If I must poll, does it have a timeout and a nonzero exit on expiry?
4. Would this break on a slower machine? A guessed duration always does.
