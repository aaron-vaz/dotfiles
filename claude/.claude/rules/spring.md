---
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/*.java"
---
# Spring Code Style

## Prefer Jakarta Validation Over Manual Checks

Single-field validation that Bean Validation can express goes on property as annotation, never as `require(...)` in `@PostConstruct` validator, `init` block, or service method.

**Why:** annotations fail at binding with property named, visible on declaration, don't drift from it. Hand-written check usually written because annotation "doesn't apply" to type, but Hibernate Validator (on classpath through Boot) covers more than Jakarta, e.g. `@DurationMin`/`@DurationMax` for `java.time.Duration` where `@Positive` does not apply.

- Before writing any `require`/`check`/`if (...) throw` on one field's value, check if annotation covers it: `@Positive`, `@PositiveOrZero`, `@Min`/`@Max`, `@NotBlank`, `@Size`, `@Pattern`, `@NotEmpty`. For `java.time.Duration` use `@DurationMin(inclusive = false)` for strictly positive (`org.hibernate.validator.constraints.time`).
- Kotlin: use `@field:` use-site target. Owning class needs `@Validated` (config properties) or `@Valid` at entry point. Nested objects/map values need `@field:Valid`.
- Keep manual code only for rules annotation cannot state: cross-field (a ≤ b, sum fits budget), cross-module, or anything needing runtime state. Custom class-level constraint possible but usually not worth it over clear validator for one or two cross-field rules.
- Durable explanation from `require` message moves to annotation's `message` or property's KDoc.
- When reviewing, flag hand-rolled single-field checks same way.