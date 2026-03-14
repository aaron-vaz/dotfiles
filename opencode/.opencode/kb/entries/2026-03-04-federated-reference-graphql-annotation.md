---
title: "@FederatedReference GraphQL Annotation — In-Process Federation POC"
date: 2026-03-04
project: claude-misc
tags: ["architecture", "kotlin", "graphql", "jvm", "debugging"]
status: active
promoted_to: ""
outcome: "Working POC — `metric: PocEGMetric` rewired from `metricId: String` at schema generation time. Build passing (143 tasks), schema verified, branch pushed."
expires: 2026-06-04
---


**Repo:** egtnl-api-orchestrator (`federation-poc-spec` branch)

## Context

Building a `@FederatedReference` annotation to enable in-process GraphQL federation routing without requiring an actual federated gateway. When a field is annotated, the schema generator rewires it: removes the raw ID field and replaces it with the resolved type, backed by an in-process `EntityResolver`.

## Key Design

```kotlin
@FederatedReference("PocEGMetric") val metricId: String
```

At schema generation time, `CustomSchemaGeneratorHooks.didGenerateGraphQLType` rewires this:
- Removes `metricId` from the GraphQL schema
- Adds `metric: PocEGMetric` field with a DataFetcher
- DataFetcher calls `PocMetricEntityResolver.resolve(env, mapOf("id" to id))` in-process

**Files changed vs master:**
- `common/graphql/FederatedReference.kt` — annotation definition
- `orchestrator/.../CustomSchemaGeneratorHooks.kt` — `didGenerateGraphQLType` override
- `poc-readout-subgraph/.../PocReadoutData.kt` — uses `@property:FederatedReference("PocEGMetric")`
- `poc-readout-subgraph/.../PocReadoutDataHttp.kt` — HTTP DTO with `metric: PocMetricStub`
- `poc-readout-subgraph/.../PocMetricStub.kt` — `data class PocMetricStub(val id: String)`
- `poc-readout-subgraph/build.gradle.kts` — depends on `:common` (not `:poc-metrics-subgraph`)

## Bugs Found and Fixed

### Bug 1: Kotlin annotation use-site target

**Problem:** `@FederatedReference("PocEGMetric") val metricId: String` in primary constructor — bare annotation without explicit use-site target. `KProperty.findAnnotation<>()` returned null.

**Fix:**
1. Added `AnnotationTarget.VALUE_PARAMETER` to `@Target` alongside `PROPERTY`
2. Changed annotation to explicit `@property:FederatedReference("PocEGMetric")` to remove ambiguity
3. Added two-path lookup in hooks: `prop.findAnnotation<>()` first, then `ctorParamAnnotations[prop.name]` fallback

**Key finding:** With `@property:` use-site, annotation IS visible on `KProperty`. The ctor param fallback covers bare-annotated cases.

### Bug 2: GraphQL NonNull wrapping

**Problem:** `didGenerateGraphQLType` receives `GraphQLNonNull(GraphQLObjectType)`, not bare `GraphQLObjectType`. The `!is GraphQLObjectType` early-return was firing immediately — hook was a no-op for all non-null types.

**Fix:** Unwrap NonNull → transform inner type → re-wrap with NonNull.

### Bug 3: Type deduplication (GraphQL Java `AssertException`)

**Problem:** `didGenerateGraphQLType` is called **twice** for `PocReadoutData` (once per query that returns it). Each transform creates a new object with the same name. GraphQL Java rejects two different objects with the same name.

**Fix:** `transformedTypeCache: MutableMap<String, GraphQLObjectType>` — cache by type name, return same object reference on repeat calls. GraphQL Java deduplicates by identity (`existingType != type`), so same ref = no assertion.

## Wrong Diagnosis (Don't Repeat)

Initially concluded it was a "multi-module Spring context scoping issue" and moved hooks to `common`. **That was wrong.** Spring has ONE ApplicationContext — all beans from all Gradle modules are in the same context. `CustomSchemaGeneratorHooks` in orchestrator IS the single hooks bean and DOES process all types. The common module refactor was unnecessary and was reverted (commit `3ca9d78`).

## Tests Added

`FederatedReferenceAnnotationTest.kt` — 4 tests, all passing:
- Verifies `@property:` use-site visible on `KProperty`
- Verifies ctor param fallback for bare annotation
- Both reflection paths confirmed working

## Commits

```
3ca9d78 revert: remove CommonSchemaGeneratorHooks and common module graphql deps
977e7f0 refactor(poc): move @FederatedReference hooks to common... (now reverted)
637d155 feat(poc): implement @FederatedReference annotation for in-process federation routing
baaca13 feat(poc): enable federation schema generation with @key directives
```

## Pending

~~Plan doc uncommitted~~ — verified clean. Worktree only has untracked `.claude/` files. Nothing to commit.

## Related

- Session: ~/.claude/sessions/current.md
- Worktree: `~/workspaces/.worktrees/egtnl-api-orchestrator/federation-poc-spec`
- Archived by: session-archiver (manual)
