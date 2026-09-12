---
name: 2026-09-05-composed-integration-test-properties-alias
description: A composed @IntegrationTest annotation that wraps @SpringBootTest must expose a `properties` attribute aliased onto SpringBootTest.properties; tests set properties there, never by stacking @TestPropertySource on top of the composed annotation. Aaron's correction on a set of live-update integration tests.
type: feedback
tags: [spring-boot, testing, integration-test, annotations, kotlin]
status: active
date: 2026-09-05
---

**Rule:** when a module has a composed `@IntegrationTest` (meta-annotated with `@SpringBootTest`),
per-test properties go through an attribute on *that* annotation —
`@IntegrationTest(properties = ["a=b"])` — declared with
`@get:AliasFor(annotation = SpringBootTest::class, attribute = "properties")`. Do not add a second
`@TestPropertySource(properties = [...])` next to it.

**Why:** Aaron, reviewing `MeetingPlanLiveBoundsIT`: "The int test annotation should delegate to
spring boot test for props." Two annotations configuring the same context is exactly what the
composed annotation exists to avoid, and it leaves a reader working out which of the two sources
wins. The alias keeps one entry point and the precedence obvious.

**How to apply:**
- Defaults the module wants on *every* IT (a sweep interval pushed out of reach, a transport
  switch) live in the composed annotation as a `@TestPropertySource` meta-annotation, not in the
  aliased attribute's default — an alias attribute *replaces* the target, so a test overriding
  `properties` would silently drop any defaults declared there.
- Precedence is the reverse of what reads naturally: `SpringBootTestContextBootstrapper.
  processPropertySourceProperties` inserts `@SpringBootTest.properties` *ahead of* the
  `@TestPropertySource` inlined properties, so the meta-annotation's defaults win over a test's
  `properties = [...]` for the same key. The defaults are therefore fixed for every IT in the
  module; a test that needs one of them to differ needs its own `@SpringBootTest`. Pick the
  defaults so no test wants to override them (the meetings ones: sweep interval, RSocket transport).
  Aliasing the attribute onto `@TestPropertySource.properties` instead does not work: a bare
  `@IntegrationTest` then carries an empty `@TestPropertySource`, which looks for a
  `<TestClass>.properties` file and fails startup.
- Constant references (`"key=$SOME_CONST"`) are fine in the attribute — annotation arguments only
  need to be compile-time constants.

Related: the originating checkpoint entry lives in the private store.
