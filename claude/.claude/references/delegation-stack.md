# Delegation Stack: Verified Harness Facts

Facts about how Claude Code behaves under the delegation setup described in `README.md` ("Delegation (subagents)"). They were verified on Claude Code 2.1.285 unless noted. Read this before changing agent definitions, the delegation hooks, or the subagent status line.

## Nesting and model resolution

- Subagents can spawn subagents. The default depth limit is 3, and `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` overrides it (set to 2 in `settings.json`).
- `Agent(type)` allowlists in a subagent's `tools:` are ignored; they only work for a main-thread agent started with `claude --agent`. Worker lists are therefore enforced by the orchestrator's prompt, and workers simply omit the `Agent` tool.
- The model for a subagent is resolved in this order: the per-call `model` parameter, then the definition's frontmatter, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main model. This is why the main thread must never pass `model` when spawning the custom agents.
- A family alias that matches the main model's family resolves to the main model's exact id, including any `[1m]` context suffix.
- Agent definitions load at session start, so a session that predates a new agent cannot spawn it. Smoke-test a new definition with a headless `claude -p` run in a temporary directory.

## Subagent status line

`subagentStatusLine` runs once per refresh tick with every visible subagent row on stdin and prints one `{"id","content"}` JSON line per row to override that row.

- Input is `{columns, tasks: [{id, type: "local_agent", status, description, label, startTime (ms), model (resolved id), contextWindowSize, tokenCount, tokenSamples[], effort?, name?}]}`.
- The payload has no agent type. `hooks/subagent-track.sh` (SubagentStart) records `agent_id` to `agent_type` under `~/.claude/state/subagents/`, and `hooks/subagent-statusline.js` joins on it.
- The format is documented at `code.claude.com/docs/en/statusline` under "Subagent status lines". When a summarising subagent claims something is undocumented, fetch the raw `.md` page with `curl` and `grep` it instead of trusting the summary.
- `tests/delegation-mechanical.sh` unit-tests the renderer with the real payload shape; the rendered panel itself was not checked by eye.

## Reports and resuming

Agents that are not the main thread deliver their final report through the `SubagentHandback` tool; text written after that call is not delivered, and plain text at the end of a run does not reach the caller. When an agent is cut off at its turn limit without reporting, resume it with `SendMessage`, ask for the report immediately with a small call budget, and re-dispatch whatever it lists as not reached as a narrower brief. The turn limits and handoff notes that prevent this are in `subagent-turn-budget-and-handoff.md`.

## Permission denies for sensitive paths

- A `permissions.deny` entry written as `Read(file_path:...)` never matches (Claude Code warns about it at startup), so such denies protect nothing. Use the path forms in `permissions.md`.
- Deny rules only cover Claude's file tools. `hooks/guard-sensitive-paths.sh` is the text-level twin for Bash and is best-effort by design: it can be evaded with variable indirection, globs or encoding, and it false-positives on any command that merely names a protected path.
- `sandbox.filesystem.denyRead` was considered and not enabled. It would be robust, but turning it on sandboxes all Bash (network domain and write limits) and would break git over SSH unless git and ssh are excluded.
