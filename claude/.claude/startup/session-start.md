# Session Startup

Execute the following immediately, then say "Ready" and wait for user input.

## 1. Load Session Context

Execute these reads in parallel:
- Read `~/.claude/sessions/current.md` to restore context from previous session (if exists)
- Read `~/.claude/persona.md` for communication style

## 1b. Offer Relevant KB Entries (if any surfaced)

If the SessionStart hook output included a `## KB entries possibly relevant to repo '<repo>'` block, do NOT load or summarize those entries yet — the hook only gave brief lines (date/slug/tags/outcome), not full content. Before saying "Ready", ask the user (via `AskUserQuestion`, multiSelect) which of the listed entries (if any) to load in full. Use their slugs as option labels. Only run `~/.claude/kb/search-kb.sh <slug> --full` for the ones they pick. If the hook produced no such block (no repo match), skip this step silently — do not mention KB at all.

## 2. Acknowledge

After loading context, output:

```
Ready.
```

## 3. Rename Tmux Session

Once you know what you're working on — after reading `sessions/current.md` or understanding the task — write a short kebab-case slug (2–4 words) to rename this tmux session:

```bash
echo 'feature-slug-here' > ~/.claude/sessions/.rename-request
```

The session renames automatically within a few seconds. Do this once per session as early as possible. Examples: `homelab-caddy-fix`, `dotfiles-cleanup`, `api-refactor`. Skip if the tmux session name already reflects the work.
