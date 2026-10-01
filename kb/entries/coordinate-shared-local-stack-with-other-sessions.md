---
name: "coordinate-shared-local-stack-with-other-sessions"
description: "Never run local tests against a shared local stack (docker compose DB, emulators, bootRun on shared ports, scenario scripts, schema ALTERs) while another agent session may be using it — message that session and agree first."
type: feedback
tags: [local-deploy, multi-session, testing, coordination, docker]
status: active
---

Before any local test that touches a shared local stack — starting a server against the shared
database, running scenario/seed scripts, `docker compose down -v`, `ALTER TABLE` on the local DB,
deleting rows — coordinate with every other running agent session on the machine first. Don't infer
"it's free" from an idle port or a quiet container list.

**Why:** Aaron's correction after a session added columns to the shared local Postgres and booted a
server against it while a parallel session was mid-verification on the same stack. Two sessions
writing one database make each other's results meaningless (sweep leases, partition cursors, test
accounts, schema drift), and a wipe destroys the other session's state outright.

**How to apply:**
- Run `ListAgents`; if any peer session is on the same repo/stack, `SendMessage` it with what you
  intend to run and for how long, and wait for agreement or its idle notice
  (`notify_when_idle: true`) before starting.
- Say what you will leave behind (schema changes, rows, running processes) and clean up or hand
  back afterwards.
- Testcontainers-based suites (`./gradlew integrationTest`) are isolated and don't need this, but
  they still contend on the Gradle cache lock — expect retries, not a shared-state conflict.
- If no coordination is possible, ask the user instead of proceeding.

## Related

- [[2026-09-22-scenario-scripts-sweep-lease-carryover]]
