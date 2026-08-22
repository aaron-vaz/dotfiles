---
name: dont-readd-deleted-content
description: When user deletes something (file, code, KB entry), don't recreate or reintroduce it later in the same session without being asked
type: feedback
tags: [workflow, editing]
status: active
---

If user deletes a file, block, or entry, treat that as intentional. Don't recreate it, restore it, or reintroduce equivalent content later without explicit ask — even if it seems useful again.

**Why:** User caught this during a documentation sweep session — a KB entry had been deleted earlier per their correction, and the session then drifted back toward re-adding equivalent content.

**How to apply:** Before writing/restoring a file or entry, check if it (or something like it) was deleted earlier in the session. If so, don't recreate without asking first.
