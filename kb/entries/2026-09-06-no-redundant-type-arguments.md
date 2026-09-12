---
name: 2026-09-06-no-redundant-type-arguments
description: Never write an explicit type argument Kotlin can infer — `ChangeChannel(name, UUID::toString, UUID::fromString)`, not `ChangeChannel<UUID>(...)`; `listOf(a, b)`, not `listOf<String>(a, b)`. Explicit args only where inference genuinely fails (empty collections, `mockk<T>()` with no declared type, a `MutableSharedFlow<T>()` with no seed). Aaron's standing correction.
type: feedback
tags: [kotlin, code-style, type-inference, generics]
status: active
date: 2026-09-06
---

**Rule:** no explicit type argument the compiler infers from the arguments or the declared type.
`ChangeChannel("ids_changed", UUID::toString, UUID::fromString)` — `T` is fixed by the function
references. `ChangeChannel("names_changed", { it }, { it })` — `T` is `String` from the lambdas.
`emptyList()` where the target type is declared; `mockk()` where the `val` has a type.

Keep the argument only where inference has nothing to go on: `MutableSharedFlow<Notification>()`,
`ConcurrentHashMap<UUID, Int>()`, `Channel<Result<T>>(UNLIMITED)`, `mockk<RSocket>(relaxed = true)`
assigned to an untyped `val`, `emptyList<String>()` passed where the parameter is generic.

**Why:** Aaron: "you also keep adding redundant type params." A redundant argument is noise that
reads as a hint the type is *not* inferable, so a reader stops to check why; and it drifts — rename
the class's parameter and the call site's argument stays. It also fails ktlint-style reviews here
on sight, so it costs a review round every time.

**How to apply:**
- After writing a call with `<...>`, delete the argument and see if it compiles. If it does, leave
  it deleted.
- Watch the habit spots: test fixtures (`ChangeChannel<String>(...)`, `listOf<Any>()`), builders
  fed by lambdas (`{ it }` fixes the type), function references (`UUID::fromString` fixes it), and
  `Mono.empty<T>()` in a chain whose type is already known.
- The reverse holds too: do not *remove* one that inference needs and rely on a
  `Nothing`-typed empty collection — `emptyList()` into a generic parameter infers `Nothing`.

Related: [[2026-09-06-assertthrows-belongs-in-then]]
