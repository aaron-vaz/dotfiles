# JVM Test Quality Best Practices

**Version**: 1.0.0
**Created**: 2026-01-07
**Scope**: Universal testing patterns for JVM/Java projects (Spring, Spring Boot, Reactive)
**Purpose**: Expert guidance for writing high-quality tests that validate behavior, not just execute code

---

## Detailed Usage Guide

### Automated Coverage Analysis & Planning

Claude Code can analyze your JaCoCo coverage reports and create a multi-step improvement plan automatically.

**Step 1: Generate Coverage Report**
```bash
./gradlew test jacocoTestReport  # Gradle
# OR
mvn test jacoco:report           # Maven
```

**Step 2: Ask Claude to Create a Plan**

Provide this prompt to Claude Code:
```
Please analyze the JaCoCo coverage report at [path/to/index.html] and create a
multi-step plan to improve coverage. Use the jvm-test-quality skill guidance.

Focus on:
1. Classes with low branch coverage (<70%) that have significant business logic
2. Exclude: POJOs, generated code, simple data classes
3. Prioritize by impact (coverage improvement potential)
4. For each target class:
   - Current coverage metrics
   - Why coverage is low (integration tested? infrastructure code? missing tests?)
   - Recommended approach (unit tests, integration tests, or accept as-is)
   - Estimated effort and impact

Create a phased plan with 3-5 high-impact targets per phase.
```

**Step 3: Claude Analyzes and Creates Plan**

Claude will use the Task tool with the Explore agent to:
- Parse the JaCoCo HTML report
- Identify low-coverage classes with business logic
- Check for existing integration tests
- Rank by impact/effort ratio
- Generate a phased improvement plan

**Example Output**:
```markdown
## Coverage Improvement Plan

### Phase 1: High-Impact, Low-Effort (Week 1-2)
1. **RateLimiter.java** (current: 45% branches)
   - Missing: Error path tests (Redis failures)
   - Impact: +8% branches
   - Effort: 2 hours (3 test methods)

2. **ValidationService.java** (current: 52% branches)
   - Missing: Edge case validation
   - Impact: +12% branches
   - Effort: 3 hours (parametrized tests)

### Phase 2: Medium Impact (Week 3-4)
...
```

### Strategic Gap Analysis Command

For advanced users, you can use Claude's Task agent directly:

```
Use the Task tool with subagent_type=Explore to analyze the JaCoCo report at
[path] and identify:
1. Classes with <70% branch coverage with significant business logic
2. Classes in [package] with untested conditional logic
3. Exclude: POJOs, auth packages, generated code
4. Rank by impact (coverage improvement potential)

Then verify which classes already have integration tests before recommending
unit tests.
```

### Tracking Progress

Use the included `jacoco-compare.py` script to track improvements:

```bash
# Save baseline before starting
python3 scripts/jacoco-compare.py --save-baseline

# After each phase, check progress
python3 scripts/jacoco-compare.py

# Output shows +/- for each metric
```

---

## Core Principles

### 1. Behavioral Verification Over Execution Testing

```java
// ❌ Bad: Just verify completion
StepVerifier.create(result).verifyComplete();

// ✅ Good: Verify behavior with proof
StepVerifier.create(result)
    .expectComplete()
    .verify();
verifyNoInteractions(mockDependency); // Proves short-circuit behavior
```

**Key Questions**:
- What should happen? (not just "did it run?")
- What should NOT happen? (side effects that should be avoided)
- What state changed? (verify outcomes, not just absence of exceptions)

### 2. Every Line Has a Reason

Before adding any test:
1. **Check parametrized tests**: Does an existing parametrized test cover this case?
2. **Check base class tests**: Does a parent class already validate this?
3. **Check similar tests**: Is there redundant coverage in the same file?

**Decision**: If existing tests already validate the behavior, don't add redundant tests.

### 3. Test What Matters, Not What's Easy

Focus on:
- ✅ Conditional logic (if/else, ternary, switch)
- ✅ Error handling paths (catch blocks, onError callbacks)
- ✅ Validation short-circuits (early returns)
- ✅ Business logic edge cases

Avoid:
- ❌ Testing framework code (Spring does this)
- ❌ Testing getters/setters on simple POJOs
- ❌ Testing trivial delegation methods
- ❌ Forcing unit tests for infrastructure code

---

## Test Design Patterns

### Parametrized Tests

**Use when**:
- Testing same behavior with different inputs
- 5+ similar test cases
- Each case is simple input→output mapping

**Don't use when**:
- Setup differs significantly between cases
- Need different assertions per case
- Behavior logic varies

**Example**:
```java
@ParameterizedTest
@CsvSource({
    "valid-path, true",
    "invalid-path, false",
    "null, false",
    "'', false"
})
void testPathMatching(String path, boolean expected) {
    boolean result = matcher.matches(path);
    assertEquals(expected, result);
}
```

### Helper Methods

**Threshold**: Create helper when setup repeated 3+ times

```java
// ❌ Bad: Repeated 10-line setup in 5 tests
@Test void test1() { /* 10 lines setup */ }
@Test void test2() { /* same 10 lines */ }

// ✅ Good: Extract to helper
private MockWebExchange createExchangeWithAuth(String token) {
    return MockServerWebExchange.from(
        MockServerHttpRequest.get("/test")
            .header("Authorization", token)
            .build()
    );
}

@Test void test1() {
    var exchange = createExchangeWithAuth("valid-token");
    // test logic
}
```

### Type-Safe Assertions

```java
// ❌ Bad: Unclear failure messages
assertTrue(result instanceof SuccessResponse);
SuccessResponse response = (SuccessResponse) result;

// ✅ Good: Clear failure message (JUnit 5.8+)
SuccessResponse response = assertInstanceOf(SuccessResponse.class, result);

// ✅ Alternative (older JUnit)
assertTrue(result instanceof SuccessResponse,
    "Expected SuccessResponse but got " + result.getClass());
SuccessResponse response = (SuccessResponse) result;
```

---

## Coverage Strategy

### Understanding Coverage Tools

**JaCoCo/Cobertura measure**:
- ✅ Unit tests (same JVM as test runner)

**NOT measured**:
- ❌ Integration tests (`@SpringBootTest` - separate context)
- ❌ Functional tests (deployed server)
- ❌ E2E tests (Docker containers, remote endpoints)

**Before claiming "low coverage"**:
1. Search codebase for integration tests of the class
2. Check for `@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest`
3. Look in test directories: `src/test`, `src/functionalTest`, `src/integrationTest`

**Key Insight**: Coverage % doesn't tell the whole story.

### When NOT to Force Unit Tests

**Infrastructure-Integrated Code needs integration tests**:

**Signs you need integration tests, not unit tests**:
1. Constructor creates non-injectable dependencies
2. Requires `@Autowired` framework components
3. Deep coupling to Spring Security / WebFlux / Data infrastructure
4. Would require excessive mocking (>5 mocks)
5. Tests would be brittle (testing implementation, not behavior)

**Example**:
```java
// ❌ Don't force unit tests
public class SecurityValidator {
    private final ServerHttpSecurity security;
    private final AuthConverter converter = new AuthConverter(); // non-injectable!

    public SecurityValidator(ServerHttpSecurity security) {
        this.security = security;
    }
    // Complex Spring Security integration...
}

// ✅ Write integration tests instead
@SpringBootTest
@ActiveProfiles("security-test")
class SecurityValidatorIntegrationTest {
    @Autowired SecurityValidator validator;
    // Test with real Spring context
}
```

**When to accept lower unit test coverage**:
- Critical code IS tested (via integration tests)
- Unit tests would require extensive mocking
- Integration tests provide better confidence
- Test quality > coverage percentage

### Target Prioritization

**Focus on high-impact, low-effort wins**:

Priority 1 - **Branch Coverage**:
- Conditional logic (if/else, switch, ternary)
- Validation short-circuits (early returns)
- Optional/null checks

Priority 2 - **Error Paths**:
- Exception handling (catch blocks)
- Reactive error handlers (onError)
- Fallback mechanisms

Priority 3 - **Edge Cases**:
- Boundary conditions
- Empty/null inputs
- Concurrent scenarios

**Efficiency Formula**:
```
Impact = (Lines Added to Coverage) / (Test Lines Written)
Priority = High Impact + Low Effort
```

---

## Code Quality Standards

### Import Best Practices

```java
// ❌ Bad: Fully-qualified names
reactor.core.publisher.Mono<String> result = service.call();

// ✅ Good: Proper imports
import reactor.core.publisher.Mono;
Mono<String> result = service.call();
```

**Exception**: Only use fully-qualified when imports conflict

### Static Imports for Assertions

```java
// ❌ Bad
import org.junit.jupiter.api.Assertions;
Assertions.assertEquals(expected, actual);

// ✅ Good
import static org.junit.jupiter.api.Assertions.*;
assertEquals(expected, actual);
```

### Test Naming Conventions

**Pattern**: `testMethodName_scenario_expectedOutcome`

```java
@Test
void isAllowed_withEmptyKey_returnsEmptyWithoutCallingDependency()

@Test
void handleError_withTimeoutException_returnsAllowedWithUnknownValues()

@Test
void convert_withValidInput_returnsSuccessResponse()
```

---

## Reactive Programming Patterns

### Verify Reactive Behavior

```java
// Test that Mono completes with expected value
StepVerifier.create(result)
    .expectNext(expectedValue)
    .verifyComplete();

// Test that Flux emits multiple values
StepVerifier.create(flux)
    .expectNext(value1, value2, value3)
    .verifyComplete();

// Test error scenarios
StepVerifier.create(result)
    .expectError(SpecificException.class)
    .verify();

// Verify no interactions after short-circuit
StepVerifier.create(result).verifyComplete();
verifyNoInteractions(mockDependency); // Proves early return
```

### Context Preservation

```java
// Ensure MDC/logging context preserved in reactive chains
return Mono.deferContextual(ctx -> {
    // Context available here
    return operation();
}).contextWrite(Context.of("key", "value"));
```

---

## Decision Frameworks

### When to Create Helper Methods

**Threshold**: 3+ similar test setups

```
If setup code > 10 lines AND repeated 3+ times:
    Create helper method or builder
Else:
    Keep inline (avoid premature abstraction)
```

### When to Use Mockito Spies

**Avoid unless**:
- Need to verify internal method calls
- Partial mocking required (real + mocked methods)

**Prefer**: Behavioral verification (`verifyNoInteractions`) over spying

### When to Mock vs Real Object

**Use mocks for**:
- External dependencies (databases, HTTP clients, message queues)
- Slow operations (network I/O, file system)
- Non-deterministic behavior (clock, random)

**Use real objects for**:
- Domain models / POJOs
- Value objects
- Simple utilities
- Framework components in integration tests

---

## Common Patterns by Framework

### Spring WebFlux / Reactive

```java
// Setup mock exchange
MockServerHttpRequest request = MockServerHttpRequest.get("/test")
    .header("Authorization", "Bearer token")
    .build();
MockServerWebExchange exchange = MockServerWebExchange.from(request);

// Test filter chains
when(chain.filter(any())).thenReturn(Mono.empty());
StepVerifier.create(filter.filter(exchange, chain))
    .verifyComplete();
verify(chain).filter(exchange);
```

### Spring Security

```java
// Mock authentication
Authentication auth = new UsernamePasswordAuthenticationToken(
    "user", "password", List.of(new SimpleGrantedAuthority("ROLE_USER"))
);

// Test with security context
SecurityContext context = SecurityContextHolder.createEmptyContext();
context.setAuthentication(auth);
SecurityContextHolder.setContext(context);
```

### JPA / Database

```java
// Use @DataJpaTest for repository tests
@DataJpaTest
class UserRepositoryTest {
    @Autowired UserRepository repository;

    @Test
    void findByEmail_existingUser_returnsUser() {
        User user = new User("test@example.com");
        repository.save(user);

        Optional<User> result = repository.findByEmail("test@example.com");

        assertTrue(result.isPresent());
        assertEquals("test@example.com", result.get().getEmail());
    }
}
```

---

## Code Review Checklist

### Test Quality
- [ ] Tests verify behavior, not just execution
- [ ] No redundant tests (check parametrized, base classes)
- [ ] Helper methods used for repeated setup (if 3+ times)
- [ ] Type assertions before casts
- [ ] Descriptive test names (scenario + outcome)
- [ ] Reactive tests use StepVerifier properly

### Coverage Strategy
- [ ] Checked for existing integration tests before adding unit tests
- [ ] All new branches tested
- [ ] Error paths covered
- [ ] Edge cases handled (null, empty, invalid input)
- [ ] Didn't force unit tests on infrastructure code

### Code Quality
- [ ] Proper imports (no fully-qualified names)
- [ ] Static imports for assertions
- [ ] No unused variables or mock setup
- [ ] Follows project conventions

---

## Anti-Patterns to Avoid

### 1. Testing Implementation Details

```java
// ❌ Bad: Brittle test of internal structure
verify(service, times(1)).internalHelperMethod();

// ✅ Good: Test observable behavior
assertEquals(expectedResult, actualResult);
verifyNoInteractions(externalDependency); // Only when it proves behavior
```

### 2. Over-Mocking

```java
// ❌ Bad: Mocking everything
@Mock private String mockString;
@Mock private Integer mockInteger;
when(mockString.length()).thenReturn(5);

// ✅ Good: Use real objects when simple
String realString = "hello";
Integer realInteger = 42;
```

### 3. Ignoring Test Failures

```java
// ❌ Very Bad: Ignoring flaky tests
@Test
@Disabled("Flaky test, fix later")
void testSomething() { }

// ✅ Good: Fix root cause (timing, shared state, etc.)
```

### 4. Massive Test Methods

```java
// ❌ Bad: Testing multiple scenarios in one test
@Test
void testEverything() {
    // 100 lines testing 5 different scenarios
}

// ✅ Good: One test per scenario
@Test void testScenario1() { }
@Test void testScenario2() { }
```

---

## Key Takeaways

1. **Test behavior, not code**: Verify what happened, not just that code ran
2. **Every line has a reason**: No redundant tests
3. **Quality > Coverage %**: Integration tests count too
4. **Infrastructure ≠ Unit testable**: Some code needs integration tests
5. **Simple over clever**: Clear test > complex parametrization
6. **Fail fast, fail clear**: Good error messages save debugging time

---

## Tools & Scripts

### JaCoCo Coverage Comparison

**Included Script**: `scripts/jacoco-compare.py`

Track coverage improvements and prevent regressions.

#### Quick Start

```bash
# 1. Generate coverage
./gradlew test jacocoTestReport      # Gradle
mvn test jacoco:report                # Maven

# 2. Save baseline
python3 scripts/jacoco-compare.py --save-baseline

# 3. Make changes, add tests

# 4. Compare
python3 scripts/jacoco-compare.py
```

#### Output

```
📊 Coverage Comparison
================================================================
Metric          Baseline    Current      Change   Status
----------------------------------------------------------------
Instructions      74.81%     76.50%      +1.69%      ✅
Branches          61.71%     63.20%      +1.49%      ✅
================================================================
✅ All coverage metrics maintained or improved!
```

#### Usage in CI/CD

```yaml
# GitHub Actions
- name: Check coverage
  run: |
    python3 scripts/jacoco-compare.py --set-baseline 70.0 60.0 65.0 68.0 65.0
    python3 scripts/jacoco-compare.py || exit 1
```

#### Features

- **Auto-discovery**: Finds Gradle/Maven reports automatically
- **Baseline tracking**: Save current as baseline for future comparisons
- **Flexible**: Works with single or multi-module projects
- **CI-friendly**: Exit codes for build gates

See `scripts/README.md` for full documentation.

---

## Version History

- **1.0.0** (2026-01-07): Initial generic skill extracted from common-api-gateway learnings
  - Covers: Test quality, coverage strategy, reactive patterns, decision frameworks
  - Applicable to: Any JVM project (Spring, Spring Boot, Reactive)
  - Key insight: Coverage metrics don't capture integration test value

---

**Maintainer Note**: This skill is generic and can be shared across teams. For repository-specific patterns, see individual project documentation.
