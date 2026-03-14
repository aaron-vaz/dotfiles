# Square OkHttp / Retrofit: Idiomatic Kotlin Patterns

**Sources:** `OkHttpClient.kt`, `Interceptor.kt`, `Response.kt`, `EventListener.kt`, `Retrofit.java`, `KotlinExtensions.kt`

---

## 1. Immutable Builder + Copy Constructor

`OkHttpClient` is fully immutable (`internal constructor`, all `val`s). The nested `Builder` is mutable. Copy constructor enables cheap "fork a client" semantics.

```kotlin
open class OkHttpClient internal constructor(builder: Builder) : Call.Factory {
    val interceptors: List<Interceptor> = builder.interceptors.toImmutableList()

    class Builder() {
        internal val interceptors: MutableList<Interceptor> = mutableListOf()

        constructor(okHttpClient: OkHttpClient) : this() {
            interceptors += okHttpClient.interceptors
        }

        fun addInterceptor(interceptor: Interceptor) = apply { interceptors += interceptor }
        fun connectTimeout(duration: KotlinDuration) = apply { ... }
        fun build(): OkHttpClient = OkHttpClient(this)
    }
}
```

- `apply { }` eliminates `return this`
- `toImmutableList()` in constructor prevents builder's mutable list from escaping
- `internal constructor` forces all instantiation through the builder

---

## 2. `fun interface` + Companion `invoke` Operator

```kotlin
fun interface Interceptor {
    fun intercept(chain: Chain): Response

    companion object {
        inline operator fun invoke(
            crossinline block: (chain: Chain) -> Response,
        ): Interceptor = object : Interceptor {
            override fun intercept(chain: Chain) = block(chain)
        }
    }

    interface Chain {
        fun proceed(request: Request): Response
        fun withConnectTimeout(timeout: Int, unit: TimeUnit): Chain  // per-request override, no global mutation
    }
}

// Both call sites valid:
val logging = Interceptor { chain -> chain.proceed(chain.request()) }
class AuthInterceptor(val token: String) : Interceptor { ... }
```

- Two call-site syntaxes for free
- `crossinline` prevents non-local returns
- `Chain.with*()` adjusts timeouts per-request without mutating global state

---

## 3. `@JvmName("-foo")` Lambda Overloads (Kotlin-only)

```kotlin
@JvmName("-addInterceptor")  // dash prefix = invalid Java identifier, hides from Java
inline fun OkHttpClient.Builder.addInterceptor(
    crossinline block: (chain: Interceptor.Chain) -> Response,
) = addInterceptor(Interceptor { chain -> block(chain) })
```

Avoids platform declaration clash for Kotlin-only overloads without `@JvmOverloads` complexity.

---

## 4. `@Deprecated` with `ReplaceWith(ERROR)` — Guided Migration

```kotlin
@Deprecated(
    message = "moved to val",
    replaceWith = ReplaceWith(expression = "interceptors"),
    level = DeprecationLevel.ERROR,
)
fun interceptors(): List<Interceptor> = interceptors
```

`DeprecationLevel.ERROR` breaks compilation immediately. `ReplaceWith` gives IDEs enough info to auto-migrate all call sites in one step.

---

## 5. Null-Object Singleton + `operator fun plus` for Composition

```kotlin
abstract class EventListener {
    open fun callStart(call: Call) {}  // empty defaults, subclasses override only what they care about

    operator fun plus(other: EventListener): EventListener =
        AggregateEventListener(listOf(this, other))

    companion object {
        @JvmField val NONE: EventListener = object : EventListener() {}
    }
}

// Composition — no list management at call site:
val listener = MetricsListener() + TracingListener() + LoggingListener()
```

---

## 6. `inline fun <reified T>` Extensions — Eliminate `::class.java`

```kotlin
// Retrofit KotlinExtensions.kt
inline fun <reified T : Any> Retrofit.create(): T = create(T::class.java)

suspend fun <T : Any> Call<T>.await(): T =
    suspendCancellableCoroutine { continuation ->
        continuation.invokeOnCancellation { cancel() }  // actually aborts the HTTP call
        enqueue(object : Callback<T> {
            override fun onResponse(call: Call<T>, response: Response<T>) {
                val body = response.body()
                if (body == null) continuation.resumeWithException(NullPointerException())
                else continuation.resume(body)
            }
            override fun onFailure(call: Call<T>, t: Throwable) = continuation.resumeWithException(t)
        })
    }
```

`suspendCancellableCoroutine` + `invokeOnCancellation` is the correct primitive — handles structured cancellation, actually aborts the underlying call.

---

## 7. Null-as-Not-Handled Factory Chain

```kotlin
abstract class Converter.Factory {
    open fun responseBodyConverter(type: Type, annotations: Array<Annotation>): Converter<ResponseBody, *>? = null
}

fun <T> findConverter(type: Type): Converter<ResponseBody, T> {
    for (factory in converterFactories) {
        factory.responseBodyConverter(type, annotations)?.let { return it as Converter<ResponseBody, T> }
    }
    error("No converter for $type")
}
```

Each factory returns `null` to pass to next. New formats added without touching existing code.

---

## 8. `@JvmField` / `@JvmStatic` on Companion

```kotlin
companion object {
    @JvmField val NONE: EventListener = ...      // Java: EventListener.NONE (field, not getter)
    @JvmStatic fun newBuilder(): Builder = ...   // Java: OkHttpClient.newBuilder() (not .Companion.)
}
```

---

## Summary Table

| Pattern | Best Application |
|---------|-----------------|
| Immutable builder + copy constructor | HTTP/gRPC client config wrappers |
| `fun interface` + `invoke` operator | Event pipeline middleware |
| `@JvmName("-foo")` lambda overload | Any builder with lambda-accepting method |
| `@Deprecated` + `ReplaceWith(ERROR)` | Domain model refactors |
| Null-object `NONE` + `operator plus` | Composable metrics/tracing listeners |
| `inline fun <reified T>` extensions | gRPC stub creation, coroutine bridges |
| Null-as-not-handled factory chain | Pluggable serializers/captors |
| `@JvmField` / `@JvmStatic` | Constants and factory methods with Java interop |