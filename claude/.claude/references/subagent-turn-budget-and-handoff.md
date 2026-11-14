# Subagent turn budget and handoff

Standard for every delegated agent and for whoever briefs it. Decided 2026-11-14 after implementers hit their turn limit mid-task and handed back nothing.

## The problem

A delegated agent has a hard turn limit (`maxTurns` in its definition; a turn is one round of tool calls). At the limit it is cut off. The controller receives no report, and any state the agent held only in its head is lost. Seen repeatedly on 40-turn implementers working on multi-file UI changes.

## Rules for the agent

1. **Know your limit.** Your definition names it ("Turn budget" section). Count your tool rounds as you go.
2. **Write the handoff note early.** For any task longer than a few steps, write it within your first 3 tool rounds, at the path the brief names (if none: `handoff-<task>.md` in the scratchpad or temp dir you were given). It holds: goal, done, remaining, state (worktree, branch, last commit, running processes), the exact next step, and commands to verify. Update it after every unit of work, so it is never more than one unit stale.
3. **Keep state outside your head.** Write files; if the brief allows git writes, commit after each unit (small commits, pushed when the brief says so). Never leave work only in the working tree across more than one unit.
4. **Budget the turns.**
   - Up to about 70% of the limit: do the work.
   - At about 70%: stop starting new units; finish the one in progress.
   - At about 85%: stop and report. A partial report beats none.
5. **Report before the limit, in the agreed format.** Use `DONE`, `PARTIAL` (with remaining work and the next step) or `BLOCKED`. Deliver it through the report channel the brief names (a report file and/or the hand-back tool).
6. **Never claim what you did not verify.** A partial report says exactly what ran and what did not.

## Rules for the controller (whoever writes the brief)

- State the turn limit in the brief, name the handoff note path and the report path, and say whether git writes are allowed.
- Size units to fit: a unit that needs more than about 60% of the limit gets split into several briefs (disjoint files), or goes to the orchestrator.
- If an agent stops at its limit without a report, resume it with a message that points at its handoff note and says what to finish first. Batch changes into one resume; do not resume with change after change.
- Read the handoff note and `git log` before trusting an agent's claim about its own progress.

## Where this lives

- Each agent definition in `~/.claude/agents/` has a "Turn budget and handoff" section with its own numbers (70% and 85% of its `maxTurns`).
- `tests/delegation-mechanical.sh` (T8e) checks every definition has the section and names its own limit.
- The delegation bullet in `AGENTS.md` points here for controllers.
