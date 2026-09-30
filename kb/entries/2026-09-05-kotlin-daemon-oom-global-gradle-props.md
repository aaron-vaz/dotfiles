---
name: 2026-09-05-kotlin-daemon-oom-global-gradle-props
description: "Kotlin compile daemon OOM ('GC overhead limit exceeded') on multi-module builds: fixed machine-wide with kotlin.daemon.jvmargs=-Xmx4g -XX:+UseParallelGC in ~/.gradle/gradle.properties (org.gradle.jvmargs does not reach it). Check first when the compiler OOMs."
type: reference
tags: [gradle, kotlin, build, oom, environment, macos]
status: active
date: 2026-09-05
---

# Kotlin compile daemon OOM — global Gradle properties

**Symptom:** `./gradlew build` on a multi-module Kotlin repo fails partway with
`e: java.lang.OutOfMemoryError: GC overhead limit exceeded` (or a `Back-end (JVM) Internal error`
whose root cause is that OOM) in an unrelated module — three times in one day on the same
multi-module repo, each time a different module. Rerunning after `./gradlew --stop` sometimes
passed because the cache absorbed most of the work; not a fix.

**Cause:** the Kotlin compile daemon's default heap, not the Gradle daemon's. `org.gradle.jvmargs`
does not reach it; `kotlin.daemon.jvmargs` does.

**Fix (applied 2026-09-05, Aaron: "add that mem args to global gradle props"):**
`~/.gradle/gradle.properties`

```properties
kotlin.daemon.jvmargs=-Xmx4g -XX:+UseParallelGC
```

Verified the daemon picks it up: `ps` on `KotlinCompileDaemon` shows `-Xmx4g -XX:+UseParallelGC`
after `./gradlew --stop` and a fresh compile. Machine has 24 GiB.

**How to apply:** if a Kotlin build OOMs in the compiler, check this property before touching the
repo. Per-repo `gradle.properties` would also work but Aaron chose global so every checkout and
worktree gets it — a worktree does not carry gitignored files, so a repo-local fix would have to
be committed.
