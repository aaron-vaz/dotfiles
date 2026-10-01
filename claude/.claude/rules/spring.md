---
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/*.java"
---

# Spring Code Style

## Prefer Jakarta Validation Over Manual Checks

Single-field validation that Bean Validation can express goes on the property as an annotation,
never as a `require(...)` in a `@PostConstruct` validator, an `init` block, or a service method.

**Why:** annotations fail at binding with the property named, are visible on the declaration, and don't drift
from it. A hand-written check is usually written because an annotation "doesn't apply" to the type, but Hibernate
Validator (on the classpath through Boot) covers more than Jakarta does, e.g. `@DurationMin`/`@DurationMax` for
`java.time.Duration` where `@Positive` does not apply.

- Before writing any `require`/`check`/`if (...) throw` on one field's value, check whether an annotation covers it:
  `@Positive`, `@PositiveOrZero`, `@Min`/`@Max`, `@NotBlank`, `@Size`, `@Pattern`, `@NotEmpty`. For
  `java.time.Duration` use `@DurationMin(inclusive = false)` for strictly positive
  (`org.hibernate.validator.constraints.time`).
- In Kotlin use the `@field:` use-site target. The owning class needs `@Validated` (config properties) or `@Valid` at
  the entry point, and nested objects/map values need `@field:Valid`.
- Keep manual code only for rules an annotation cannot state: cross-field (a ≤ b, a sum fits a budget), cross-module,
  or anything needing runtime state. A custom class-level constraint is an option but usually not worth it over a
  clear validator for one or two cross-field rules.
- A durable explanation that lived in the `require` message moves to the annotation's `message` or the property's KDoc.
- When reviewing, flag hand-rolled single-field checks the same way.
