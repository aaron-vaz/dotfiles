---
title: "@FederatedReference — GraphQL Schema Rewiring via Kotlin Annotation"
date: 2026-03-04
project: claude-misc
tags: ["kotlin", "graphql", "annotation-reflection", "architecture", "spring-boot", "multi-module"]
status: active
promoted_to: ""
outcome: "Working `@FederatedReference` annotation that rewires GraphQL schema at generation time to replace ID fields with resolved entity types"
expires: 2026-06-04
---

## Context

POC for in-process federation in `egtnl-api-orchestrator` (`federation-poc-spec` branch). Goal: annotate an ID field in a GraphQL type to have the schema automatically replace it with a resolved entity field backed by an in-process DataFetcher — without actual Apollo Federation.

```kotlin
@FederatedReference("PocEGMetric") val metricId: String
// schema gets: metric: PocEGMetric (not metricId: String)
```

## Key Decisions

- **`CustomSchemaGeneratorHooks.didGenerateGraphQLType`** — the right hook point. Called once per GraphQL type during schema generation. Inspects Kotlin class properties, rewires fields.
- **Single Spring ApplicationContext** — Spring has ONE context across all Gradle modules. Moving hooks to `common` was wrong; `CustomSchemaGeneratorHooks` in `orchestrator` processes types from all modules. Reverted that refactor.
- **Two-path annotation lookup** — needed because Kotlin ctor param annotation placement is ambiguous without explicit use-site target.
- **Transform cache by type name** — `didGenerateGraphQLType` is called once per *query* that references a type, not once per type. Multiple calls → multiple `GraphQLObjectType` instances with same name → GraphQL Java assertion error.

## Solution / Outcome

### Annotation placement fix

`@Target(PROPERTY)` alone is insufficient for ctor params — bare annotation goes to `param`, not `property`. Fix:
1. Add `AnnotationTarget.VALUE_PARAMETER` to `@Target` in `FederatedReference.kt`
2. Use explicit `@property:FederatedReference(...)` at call site to remove ambiguity

### Two-path lookup in hooks

```kotlin
val ctorParamAnnotations = type.kotlin.primaryConstructor
    ?.parameters
    ?.associateBy({ it.name }, { it.findAnnotation<FederatedReference>() })
    ?: emptyMap()

for (prop in type.kotlin.memberProperties) {
    val ref = prop.findAnnotation<FederatedReference>()
        ?: ctorParamAnnotations[prop.name]
        ?: continue
    // rewire field
}
```

### Unwrap GraphQLNonNull before transforming

`didGenerateGraphQLType` receives `GraphQLNonNull(GraphQLObjectType)`, not bare `GraphQLObjectType`. The `!is GraphQLObjectType` guard fires too early:

```kotlin
val (objectType, isNonNull) = when (type) {
    is GraphQLNonNull -> (type.wrappedType as? GraphQLObjectType ?: return type) to true
    is GraphQLObjectType -> type to false
    else -> return type
}
val transformed = transform(objectType)
return if (isNonNull) GraphQLNonNull(transformed) else transformed
```

### Transform cache to avoid duplicate type names

```kotlin
private val transformedTypeCache = ConcurrentHashMap<String, GraphQLObjectType>()

// in didGenerateGraphQLType:
transformedTypeCache.getOrPut(objectType.name) { buildTransformedType(objectType) }
```

GraphQL Java deduplicates by identity (`existingType != type` check in registry). Same object reference = no `AssertException: No two provided types may have the same name`.

## Lessons Learned

- **Don't assume multi-module = multiple Spring contexts.** Gradle modules ≠ Spring contexts. One `@SpringBootApplication` = one context, all beans visible everywhere.
- **Kotlin annotation placement on ctor params is ambiguous.** With `@Target(PROPERTY, VALUE_PARAMETER)`, bare annotation goes to `param`. Use `@property:` explicitly or handle both paths in reflection code.
- **GraphQL hooks fire per-usage, not per-type.** If a type appears in N queries, `didGenerateGraphQLType` fires N times. Cache transforms by type name.
- **GraphQLNonNull wrapping.** Schema generation wraps non-null types. Always unwrap before `is GraphQLObjectType` check.

## Key Files (federation-poc-spec branch)

- `common/src/main/kotlin/com/expedia/egtnl/orchestrator/common/graphql/FederatedReference.kt`
- `orchestrator/src/main/kotlin/com/expedia/egtnl/orchestrator/graphql/CustomSchemaGeneratorHooks.kt`
- `poc-readout-subgraph/src/main/kotlin/com/expedia/egtnl/poc/readout/dto/PocReadoutData.kt`
- `orchestrator/src/test/kotlin/.../FederatedReferenceAnnotationTest.kt`

## Related

- Branch: `federation-poc-spec` in `egtnl-api-orchestrator`
- Session: `~/.claude/sessions/current.md` (2026-03-04)
