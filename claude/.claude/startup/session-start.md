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

Once you know what you're working on — after understanding the task — write a short kebab-case slug (2–4 words) to rename this tmux session:

```bash
echo 'feature-slug-here' > ~/.claude/sessions/.rename-request
```

The session renames automatically within a few seconds. Do this once per session as early as possible. Examples: `homelab-caddy-fix`, `dotfiles-cleanup`, `api-refactor`. Skip if the tmux session name already reflects the work.
