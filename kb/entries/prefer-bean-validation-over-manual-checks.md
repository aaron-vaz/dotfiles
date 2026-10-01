---
name: prefer-bean-validation-over-manual-checks
description: "Never hand-write single-field checks (require(x > 0), isPositive, blank/size) that a Jakarta/Hibernate Validator annotation can express; annotate the property of a @Validated class (Duration: @DurationMin/@DurationMax). Manual code only for cross-field or cross-module rules."
type: feedback
tags: [kotlin, spring-boot, validation, bean-validation, configuration-properties, code-style]
status: active
---

Single-field validation that Bean Validation can express goes on the property as an annotation,
never as a `require(...)` in a `@PostConstruct` validator, an `init` block, or a service method.

**Why:** Aaron's correction on a `@PostConstruct` config validator, which carried `require(policy.window.isPositive)`
and four siblings on the reasoning "`@Positive` does not apply to a `Duration`". True of the Jakarta
annotation, but Hibernate Validator (already on the classpath through Boot) ships `@DurationMin` /
`@DurationMax` for `java.time.Duration`, and the class was already `@Validated` with `@Valid` cascading.
Annotations fail at binding with the property named, are visible on the declaration, and don't drift
from it.

**How to apply:**
- Before writing any `require`/`check`/`if (...) throw` on one field's value, check whether an
  annotation covers it: `@Positive`, `@PositiveOrZero`, `@Min`/`@Max`, `@NotBlank`, `@Size`,
  `@Pattern`, `@NotEmpty`; for `java.time.Duration` use `@DurationMin(inclusive = false)` for
  strictly positive (Hibernate, `org.hibernate.validator.constraints.time`).
- In Kotlin use the `@field:` use-site target; the owning class needs `@Validated` (config
  properties) or `@Valid` at the entry point, and nested objects/map values need `@field:Valid`.
- Keep manual code only for rules an annotation cannot state: cross-field (a ≤ b, a sum fits a
  budget), cross-module, or anything needing runtime state. A custom class-level constraint is an
  option but usually not worth it over a clear validator for one or two cross-field rules.
- A durable explanation that lived in the `require` message moves to the annotation's `message` or
  the property's KDoc.
- When reviewing, flag hand-rolled single-field checks the same way.
