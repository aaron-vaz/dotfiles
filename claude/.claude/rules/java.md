---
paths:
  - "**/*.java"
---

# Java Code Style

## Java Logging (Lombok)
Use `@Slf4j` annotation — no manual `Logger` fields.

## Java `final` — Use Liberally
Apply `final` to all method parameters and all local variable declarations unless the variable is intentionally reassigned.

```java
// Good
public void process(final String id, final int count) {
    final MetricConfig config = metricConfigMap.get(id);
    final boolean skip = shouldSkip(config);
}

// Bad — missing final on params and locals
public void process(String id, int count) {
    MetricConfig config = metricConfigMap.get(id);
    boolean skip = shouldSkip(config);
}
```

Exception: loop variables being incremented (`for (int i = 0; ...)`), variables reassigned in branches.

## Java Braces
Always use braces for `if`, `else`, `for`, `while` — even single-line bodies.
