---
title: "@FederatedReference: In-Process Federation Routing via Schema Hooks"
date: 2026-03-04
project: claude-misc
tags: ["graphql", "kotlin", "graphql-kotlin", "federation", "annotation-processing", "spring", "reflection"]
status: active
promoted_to: ""
outcome: "Implemented `@FederatedReference` annotation that rewires ID fields to resolved federation types at schema generation time via `CustomSchemaGeneratorHooks`"
expires: 2026-06-04
---

## Context

POC exploring GraphQL federation in `egtnl-api-orchestrator`. The `poc-readout-subgraph` receives readout data from HTTP with a raw `metricId: String`. The goal was to have the GraphQL schema expose `metric: PocEGMetric` instead — resolved in-process via the metric entity resolver — without splitting into actual separate subgraph services.

## Key Decisions

- **Annotation target:** `@Target(AnnotationTarget.PROPERTY, AnnotationTarget.VALUE_PARAMETER)` — needed both because Kotlin constructor params without explicit use-site target are ambiguous; added `VALUE_PARAMETER` as fallback target, but final usage switched to explicit `@property:FederatedReference(...)` to remove ambiguity entirely
- **Hook location:** `CustomSchemaGeneratorHooks` in orchestrator module (NOT moved to common). Spring has a single `ApplicationContext` — all beans from all Gradle modules share it. Moving hooks to `common` was wrong and reverted.
- **NonNull unwrapping:** `didGenerateGraphQLType` receives `GraphQLNonNull(GraphQLObjectType)`, not bare `GraphQLObjectType`. Early return was firing immediately. Fix: unwrap NonNull, transform inner type, re-wrap.
- **Transform cache:** `didGenerateGraphQLType` is called multiple times for the same type (once per query that references it). Each call creates a new `GraphQLObjectType` with the same name → GraphQL Java assertion error ("No two provided types may have the same name"). Fix: `transformedTypeCache` keyed by type name — return same object reference on repeat calls.

## Solution / Outcome

```kotlin
// FederatedReference.kt
@Target(AnnotationTarget.PROPERTY, AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
annotation class FederatedReference(val type: KClass<*>)

// Usage in PocReadoutData.kt
@property:FederatedReference(PocEGMetric::class)
val metricId: String
```

`CustomSchemaGeneratorHooks.didGenerateGraphQLType`:
1. Check if type is `GraphQLNonNull` — if so, unwrap and process inner type, then re-wrap
2. For each `KProperty` on the Kotlin type, check for `@FederatedReference` annotation
3. Two-path annotation lookup: `prop.findAnnotation<FederatedReference>()` first, then `ctorParam.findAnnotation<FederatedReference>()` fallback
4. Remove the ID field, add a new field that calls `FederatedTypeSuspendResolver.resolve(env, mapOf("id" to id))`
5. Cache transformed type in `transformedTypeCache` by name — return cached version on repeat calls

**Verified:** Schema introspection shows `metric: PocEGMetric`, no `metricId: String`.

## Code / Commands

```bash
# Verify schema after boot
curl -s http://localhost:8082/graphql -d '{"query":"{ __type(name:\"PocReadoutData\") { fields { name } } }"}' | jq
```

```kotlin
// Two-path annotation lookup
val annotation = prop.findAnnotation<FederatedReference>()
    ?: kClass.primaryConstructor?.parameters
        ?.firstOrNull { it.name == prop.name }
        ?.findAnnotation<FederatedReference>()
```

```kotlin
// NonNull unwrap + re-wrap pattern
val (innerType, wasNonNull) = if (type is GraphQLNonNull) {
    type.wrappedType as? GraphQLObjectType to true
} else {
    type as? GraphQLObjectType to false
}
// ... transform innerType ...
return if (wasNonNull) GraphQLNonNull(transformed) else transformed
```

```kotlin
// Transform cache
private val transformedTypeCache = ConcurrentHashMap<String, GraphQLObjectType>()

override fun didGenerateGraphQLType(...): GraphQLType {
    transformedTypeCache[typeName]?.let { return if (wasNonNull) GraphQLNonNull(it) else it }
    // ... do transform ...
    transformedTypeCache[typeName] = transformed
}
```

## Lessons Learned

- **Spring single context:** When using Spring Boot with multiple Gradle modules scanned via `graphql.packages`, all beans from all modules land in one `ApplicationContext`. There's no per-module scoping. A hooks bean in one module processes types from all modules.
- **Kotlin annotation use-site targets on ctor params:** Without explicit `@property:` prefix on constructor params, bare annotations go to the parameter (not the property). With `@Target(PROPERTY)` only, `findAnnotation<>()` on `KProperty` returns null. Use explicit `@property:` use-site target to be unambiguous.
- **GraphQL type identity:** `graphql-java` deduplicates types by object identity (`existingType != type`). If you create two different `GraphQLObjectType` instances with the same name, you get an `AssertException`. When transforming types in `didGenerateGraphQLType`, cache by name and return the same reference on subsequent calls.
- **didGenerateGraphQLType receives NonNull wrappers:** Don't assume the incoming type is always a bare `GraphQLObjectType`. Unwrap and re-wrap.

## Related

- Branch: `federation-poc-spec` in `~/workspaces/.worktrees/egtnl-api-orchestrator/federation-poc-spec`
- Plan doc: `docs/plans/2026-03-04-federation-poc-impl.md` (committed in `8a07f17`)
- Test: `FederatedReferenceAnnotationTest.kt` — 4 tests covering both reflection paths
- Commits: `637d155` (initial), `977e7f0` (reverted common move), `3ca9d78` (revert), fix commits
