---
globs: ["*.py", "**/*.py"]
---

# Python Code Style (FastAPI/asyncio)

## Async / Sync Boundaries

- **Sync I/O from async handlers blocks event loop** — use `asyncio.to_thread()` or make method async
- Detection: `def` (not `async def`) calling `requests.*`, `httpx.Client`, `TokenRetriever`, file I/O — called from `async def` handler
- **Double-checked locking** — capture local ref before checking attributes outside lock (TOCTOU race)
- **`asyncio.Lock` for coroutines**, `threading.Lock` only for OS threads

## Exception Handling

- **Narrow catches** — don't catch `Exception` when only `OSError` (or similar) is recoverable
- **Error codes** — use `UNAVAILABLE` for transient infra failures, `INTERNAL` for code bugs
- **Never `except:` or `except BaseException:`** — catches `KeyboardInterrupt`, `SystemExit`

## Module-Level Side Effects

- **No file I/O at import time** — wrap in function or lazy-load
- **No bare `dict["key"]` at import time** — use `.get()` with validation

## Auth / Security

- Before flagging auth removal as critical, check if mesh-level auth (`enableDryRun: false`) is enforcing
- Don't depend on `_internal` modules — use public APIs

## Logging

- `logger.warning()` for startup conditions causing request failures (not `info`)
- Only add missing-field warnings if field is actually nullable in schema

## Token Caching

- Cache `(token, expiry)` pairs; refresh only when expired
- Before flagging: check if underlying auth library already caches internally

## Type Hints Compatibility

- **`X | Y` union syntax requires Python 3.10+** — on 3.9, use `Optional[X]` or `Union[X, Y]` from `typing`
- Script may run on system Python (3.9) → use `from __future__ import annotations` to enable PEP 604 syntax at parse time

## Subprocess

- **Capturing third-party tool output: use `encoding="utf-8", errors="replace"` — not `text=True`.** `text=True` decodes with system locale; non-UTF-8 locales (or any binary byte) raise `UnicodeDecodeError` mid-stream. Tools emitting en-dashes, smart quotes, or unicode citations (search/AI CLIs, `gh`, `jq` output) crash on the first multibyte char. `errors="replace"` keeps substitution char `<EFBFBD>` instead of losing whole call.
- Long-running external CLIs need explicit `timeout=` — never inherit parent timeout. Return structured error string on `subprocess.TimeoutExpired` rather than letting it bubble.

## Dependencies

- Pin tool versions in Dockerfiles — unpinned `grpcio-tools>=1.62.0` breaks on next build

## gRPC

- Add `appProtocol: grpc` to port definitions in `values.yaml`
- Let non-recoverable gRPC startup errors propagate (don't catch with broad `except Exception`)

## Testing

- `pytest-anyio` or `pytest-asyncio` required for async tests — without decorators, tests silently skipped
- Use `AsyncMock` for coroutines, `MagicMock` for sync
- No `pytest.ini` → test discovery may silently miss files

## FastAPI

- Don't mutate `_internal` FastAPI state — use conditional middleware or flags
- Use `lifespan` context manager for startup/shutdown resource management