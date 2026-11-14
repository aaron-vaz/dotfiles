---
name: "coordinate-shared-local-stack-with-other-sessions"
description: "Never run local tests against a shared local stack (docker compose DB, emulators, servers on shared ports, scenario scripts, schema ALTERs) while another agent session may be using it. Message that session and agree first."
type: feedback
tags: [local-deploy, multi-session, testing, coordination, docker]
status: active
---

Before any local test that touches a shared local stack, coordinate with every other running agent session on the machine first. This covers starting a server against the shared database, running scenario or seed scripts, `docker compose down -v`, `ALTER TABLE` on the local DB and deleting rows. Do not infer "it is free" from an idle port or a quiet container list.

**Why:** Two sessions writing to one database make each other's results meaningless (sweep leases, partition cursors, test accounts, schema drift). A wipe destroys the other session's state outright. This was learned when one session added columns to the shared local Postgres and booted a server against it while a parallel session was mid-verification on the same stack.

**How to apply:**
- List the other running agent sessions. If any peer is on the same repo or stack, message it with what you intend to run and for how long. Wait for agreement or for its idle notice before you start. (In Claude Code, `ListAgents` and `SendMessage` do this.)
- Say what you will leave behind (schema changes, rows, running processes). Clean up or hand it back afterwards.
- Testcontainers-based suites are isolated and do not need this. They still contend on the Gradle cache lock, so expect retries, not a shared-state conflict.
- If no coordination is possible, ask the user instead of proceeding.
