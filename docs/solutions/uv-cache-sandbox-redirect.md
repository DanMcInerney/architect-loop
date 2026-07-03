# uv Cache Sandbox Redirect

## Problem

`uv run` validator gates failed in the Codex sandbox because uv tried to write
under the user AppData cache, which was denied with os error 5.

## What Didn't Work

Running the exact frozen command without an in-workspace cache. The command was
logically correct, but its default cache location was outside the writable
sandbox.

## Why This Works

Setting `UV_CACHE_DIR=.architect/tmp/uv-cache` keeps uv's cache writes inside
the workspace. The validator command still executes the same test entry point,
and the cache redirect is recorded as a same-pattern substitution.

## Prevention

Gate files should name the uv cache redirect as permitted for
write-restricted sandboxes. Validator gates stay runnable when all temp and
cache paths are under `.architect/tmp/`.
