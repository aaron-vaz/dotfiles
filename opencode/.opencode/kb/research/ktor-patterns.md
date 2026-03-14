# Ktor: Idiomatic Kotlin Patterns

**Sources:** `HttpClientConfig.kt`, `HttpRequestRetry.kt`, `HttpTimeout.kt`, `Pipeline.kt`

---

## 1. DSL Builder with `@KtorDsl` (`@DslMarker`) + Lambda Accumulation

```kotlin
@KtorDsl  // @DslMarker — prevents outer DSL functions leaking into inner blocks
class HttpClientConfig<T : HttpClientEngineConfig> {
    fun engine(block: T.() -> Unit) {
        val oldConfig = engineConfig
        engineConfig = { oldConfig(); block() }  // accumulates, doesn't replace
    }

    fun <TBuilder : Any, TPlugin : Any> install(
        plugin: HttpClientPlugin<TBuilder, TPlugin>,
        configure: TBuilder.() -> Unit = {}     // default = {} avoids overloading
    ) { ... }
}
```

Lambda accumulation means order is preserved and calls compose. `@DslMarker` gives compile-time DSL scope safety.

---

## 2. Plugin Installation with `AttributeKey` Identity (Idempotent)

```kotlin
private fun <TBuilder : Any, TPlugin : Any> installPlugin(plugin: HttpClientPlugin<TBuilder, TPlugin>) {
    if (plugins.containsKey(plugin.key)) return   // idempotent — calling install() twice is safe

    plugins[plugin.key] = { scope ->
        val pluginData = plugin.prepare(config)   // pure config building
        plugin.install(pluginData, scope)          // side-effectful wiring, separate step
        attributes.put(plugin.key, pluginData)
    }
}
```

Two-step `prepare + install` separates pure config from side-effectful wiring. `AttributeKey<T>` gives typed identity.

---

## 3. Named Phase Pipeline (Suspend-Native)

```kotlin
// From HttpRequestRetry — suspend-native interceptor:
on(Send) { request ->
    while (true) {
        val subRequest = prepareRequest(request)
        call = try {
            proceed(subRequest)
        } catch (cause: Throwable) {
            if (!shouldRetry(...)) throw cause
        }
        if (!shouldRetry(...)) break
        delay(delayMillis(...))
    }
    call
}
```

`proceed()` is a suspend function — async work is natural inside interceptors. Named phases (`Send`, `Receive`) allow ordered, composable cross-cutting concerns.

---

## 4. `CoroutineScope` + `SupervisorJob` for Failure Isolation

```kotlin
// HttpClient implements CoroutineScope with SupervisorJob
val coroutineContext = SupervisorJob() + dispatcher

// Closing the client completes the job → cancels all in-flight work
override fun close() { coroutineContext.cancel() }
```

`SupervisorJob` means one coroutine failure doesn't cancel siblings. Inject delay as a suspend lambda for testability:

```kotlin
var delayMillis: suspend (Long) -> Unit = { kotlinx.coroutines.delay(it) }
// In tests: config.delayMillis = { /* instant */ }
```

---

## 5. Scoped Context Classes with `internal constructor`

```kotlin
class HttpRetryShouldRetryContext(val retryCount: Int)
class HttpRetryDelayContext internal constructor(
    val request: HttpRequestBuilder,
    val response: HttpResponse?,
    val cause: Throwable?
)

internal lateinit var shouldRetry: HttpRetryShouldRetryContext.(HttpRequest, HttpResponse) -> Boolean
internal lateinit var delayMillis: HttpRetryDelayContext.(Int) -> Long
```

Each phase gets a receiver type exposing only relevant data. `internal constructor` prevents external construction while keeping the class public. Self-documenting API surface.

---

## 6. Resilience Plugin Design

```kotlin
init { retryOnExceptionOrServerErrors(3); exponentialDelay() }

fun exponentialDelay(
    base: Double = 2.0,
    baseDelayMs: Long = 1000,
    maxDelayMs: Long = 60000,
    randomizationMs: Long = 1000,
) {
    delayMillis { retry ->
        minOf((base.pow(retry - 1) * baseDelayMs).toLong(), maxDelayMs) + randomMs(randomizationMs)
    }
}

private fun checkTimeoutValue(value: Long?): Long? {
    require(value == null || value > 0) { "Only positive timeout values are allowed..." }
    return value
}
```

Sensible defaults via `init`. Exponential backoff with jitter built in. `require` for validation, not if/throw.

---

## Summary Table

| Pattern | Applicable to egtnl-learnings-api |
|---------|----------------------------------|
| `@DslMarker` DSL builder | `GrpcChannelConfig`, `EventsFlowConfig` |
| Plugin install with `AttributeKey` | gRPC interceptor registry |
| Named phase pipeline | Multi-step capture pipeline |
| `CoroutineScope` + `SupervisorJob` | Per-listener failure isolation |
| Scoped context classes `internal constructor` | `CaptureContext` for event handling |
| Injectable `delay` suspend lambda | Testable retry in `ReadoutLearningsService` |
| Resilience plugin defaults | EAO retry with exponential backoff + jitter |