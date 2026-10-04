# Session Startup

Execute the following immediately, then say "Ready" and wait for user input.

## 1. Load Session Context

Read `~/.claude/persona.md` for communication style.

## 1b. Load KB Index (autonomous paging)

Read the KB index to know what entries exist:

```bash
cat ~/.agents/kb/index.tsv | head -30
```

Or use search:

```bash
~/.agents/kb/search-kb.sh --brief | head -20
```

**Do NOT load full entries yet.** Index is the cache; entries are main memory. Page in full entries via `~/.agents/kb/search-kb.sh <slug> --full` only when a task makes them relevant.

**Do NOT ask user which entries to load.** Agent autonomously decides what to page in based on task context (thesis §5.1 — agent is the pager).

## 2. Acknowledge

After loading context, output:

```
Ready.
```

## 3. Rename Tmux Session

Name the session so the user can tell parallel sessions apart. Write a short kebab-case slug (2–4 words) describing the work:

```bash
echo 'feature-slug-here' > ~/.claude/sessions/.rename-request
```

The session renames automatically within a few seconds. Examples: `homelab-caddy-fix`, `dotfiles-cleanup`, `api-refactor`, `instrument-v02-audit`.

**When (hard rule, not a nice-to-have):**
- The startup turn only says "Ready" — there is no task yet, so do NOT rename then.
- On the **first user message that states a task**, make the rename the **first tool call of that turn**, before any reading, searching or delegating. If the startup context and the task arrive in the same turn, do the startup reads, then rename before starting the task.
- Name the work, not the repo: `social-sync-api` alone is useless; `meeting-venue-fix` says what the session is for.
- **Self-check:** before ending your first substantive turn, if you have not written a `.rename-request` this session, write it now. Never finish a first turn unnamed.
- **Re-name once** if the work pivots to a clearly different task mid-session (new ticket, new repo, new topic). Do not rename for sub-steps of the same task.
- Skip only if the tmux session name already reflects the work.

Subagents and delegated sessions do not rename; only the main session does. If you spawn or message other sessions for the user, mention the main session's slug when reporting so the user can map names to work.
