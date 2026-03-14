# JVM Test Quality Skill - Example Usage

This document demonstrates how to use the jvm-test-quality skill to automatically generate coverage improvement plans.

## Scenario

A team has a Spring Boot microservice with current coverage:
- **Instructions**: 68%
- **Branches**: 52%
- **Goal**: 85% across all metrics

## Step 1: Generate JaCoCo Report

```bash
./gradlew test jacocoTestReport
```

Report generated at: `build/reports/jacoco/test/html/index.html`

## Step 2: Provide Prompt to Claude Code

```
Please analyze the JaCoCo coverage report at build/reports/jacoco/test/html/index.html
and create a multi-step plan to improve coverage. Use the jvm-test-quality skill guidance.

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

## Step 3: Claude's Analysis and Plan

### Coverage Analysis Report

**Current State (from JaCoCo report)**:
- Total Instructions: 68%
- Total Branches: 52%
- Total Complexity: 61%
- Gap to 85% target: -17% instructions, -33% branches

**Classes Analyzed**: 87 classes
**Excluded**: 15 POJOs, 8 generated classes

### High-Impact Targets Identified

| Class | Instructions | Branches | Complexity | Business Logic | Recommendation |
|-------|--------------|----------|------------|----------------|----------------|
| PaymentProcessor.java | 45% | 28% | 42% | High | Unit tests |
| ValidationService.java | 62% | 38% | 55% | High | Unit tests |
| AuthenticationFilter.java | 0% | 0% | 0% | High | Integration tests exist ✓ |
| CacheManager.java | 71% | 44% | 63% | Medium | Unit tests |
| RetryHandler.java | 58% | 32% | 51% | Medium | Unit tests |

**Key Finding**: AuthenticationFilter has 0% unit coverage but 18 integration tests found in `src/test/java/integration/AuthenticationFilterTest.java`. Accept as-is.

---

## Multi-Phase Improvement Plan

### Phase 1: High-Impact, Low-Effort (Week 1-2)
**Target**: +8% instructions, +15% branches

#### 1. PaymentProcessor.java
- **Current**: 45% instructions, 28% branches
- **Missing Coverage**:
  - Error paths: Payment gateway timeout (line 145-160)
  - Error paths: Insufficient funds handling (line 210-225)
  - Edge case: Concurrent payment attempts (line 185-195)
- **Recommended Tests**:
  ```java
  @Test void processPayment_gatewayTimeout_retriesWithBackoff()
  @Test void processPayment_insufficientFunds_returnsError()
  @Test void processPayment_concurrentAttempts_preventsDuplicates()
  ```
- **Estimated Effort**: 4 hours
- **Expected Gain**: +18% instructions, +25% branches for this class
- **Impact on Total**: +2% instructions, +3% branches

#### 2. ValidationService.java
- **Current**: 62% instructions, 38% branches
- **Missing Coverage**:
  - Null/empty input validation (line 45-60)
  - Complex validation rules (line 110-140)
  - Format validation edge cases (line 175-190)
- **Recommended Tests**: Use parametrized tests
  ```java
  @ParameterizedTest
  @MethodSource("invalidInputs")
  void validate_invalidInput_throwsValidationException(String input)
  ```
- **Estimated Effort**: 3 hours
- **Expected Gain**: +20% instructions, +35% branches for this class
- **Impact on Total**: +3% instructions, +5% branches

#### 3. RetryHandler.java
- **Current**: 58% instructions, 32% branches
- **Missing Coverage**:
  - Max retry exhausted (line 55-65)
  - Exponential backoff calculation (line 88-95)
  - Circuit breaker integration (line 120-130)
- **Recommended Tests**:
  ```java
  @Test void retry_maxAttemptsExceeded_throwsRetryExhaustedException()
  @Test void retry_backoffCalculation_increasesExponentially()
  @Test void retry_circuitBreakerOpen_skipRetries()
  ```
- **Estimated Effort**: 3 hours
- **Expected Gain**: +25% instructions, +40% branches for this class
- **Impact on Total**: +3% instructions, +4% branches

**Phase 1 Total Impact**: +8% instructions, +12% branches
**Phase 1 Total Effort**: 10 hours

---

### Phase 2: Medium Impact, Medium Effort (Week 3-4)
**Target**: +5% instructions, +8% branches

#### 1. CacheManager.java
- **Current**: 71% instructions, 44% branches
- **Missing Coverage**:
  - Cache eviction policies (line 145-170)
  - TTL expiration edge cases (line 200-220)
  - Cache miss handling (line 95-105)
- **Recommended Tests**: Focus on state-based testing
  ```java
  @Test void evict_lruPolicy_removesOldestEntry()
  @Test void get_expiredEntry_triggersRefresh()
  ```
- **Estimated Effort**: 5 hours
- **Expected Gain**: +15% instructions, +30% branches for this class
- **Impact on Total**: +2% instructions, +4% branches

#### 2. Additional targets...
(Continue with 2-3 more classes)

**Phase 2 Total Impact**: +5% instructions, +8% branches
**Phase 2 Total Effort**: 12 hours

---

### Phase 3: Remaining Gaps (Week 5-6)
**Target**: +4% instructions, +13% branches

Focus on:
- Edge cases in existing classes
- Error recovery paths
- Complex conditional logic in service classes

**Phase 3 Total Impact**: +4% instructions, +13% branches
**Phase 3 Total Effort**: 15 hours

---

## Summary

### Projected Coverage After All Phases

| Metric | Current | Phase 1 | Phase 2 | Phase 3 | Final | Target | Status |
|--------|---------|---------|---------|---------|-------|--------|--------|
| Instructions | 68% | 76% | 81% | 85% | **85%** | 85% | ✅ Met |
| Branches | 52% | 64% | 72% | 85% | **85%** | 85% | ✅ Met |
| Complexity | 61% | 68% | 76% | 84% | **84%** | 85% | ⚠️ Close |

### Total Effort
- **Phase 1**: 10 hours (2 weeks)
- **Phase 2**: 12 hours (2 weeks)
- **Phase 3**: 15 hours (2 weeks)
- **Total**: 37 hours over 6 weeks

### Recommendations

1. **Start with Phase 1**: High-impact, low-effort wins to build momentum
2. **Use jacoco-compare.py**: Track progress after each phase
   ```bash
   python3 scripts/jacoco-compare.py --save-baseline  # Before starting
   python3 scripts/jacoco-compare.py                  # After each phase
   ```
3. **Verify integration tests**: Before writing unit tests, check for existing integration tests
4. **Behavioral verification**: Focus on testing what happens, not just that code runs
5. **Accept**: AuthenticationFilter at 0% unit coverage is fine - has 18 integration tests

---

## Tracking Progress with jacoco-compare.py

### Initial Baseline

```bash
$ python3 scripts/jacoco-compare.py --save-baseline
💾 Baseline saved to .jacoco-baseline.json
```

### After Phase 1

```bash
$ python3 scripts/jacoco-compare.py

📊 Coverage Comparison
======================================================================
Metric            Baseline    Current       Change   Status
----------------------------------------------------------------------
Instructions        68.00%     76.20%       +8.20%       ✅
Branches            52.00%     64.50%      +12.50%       ✅
Complexity          61.00%     68.10%       +7.10%       ✅
Lines               67.50%     75.80%       +8.30%       ✅
Methods             65.20%     72.40%       +7.20%       ✅
======================================================================
✅ All coverage metrics maintained or improved!
```

### CI/CD Integration

Add to `.github/workflows/ci.yml`:

```yaml
- name: Check coverage hasn't decreased
  run: |
    python3 scripts/jacoco-compare.py --set-baseline 68.0 52.0 61.0 67.5 65.2
    python3 scripts/jacoco-compare.py || exit 1
```

---

## Key Patterns Used

### 1. Behavioral Verification

```java
// ❌ Bad: Just verify completion
verify(paymentGateway).processPayment(any());

// ✅ Good: Verify behavior
verify(paymentGateway, times(3)).processPayment(any());  // Retried 3 times
assertEquals(PaymentStatus.FAILED, result.getStatus()); // Failed after retries
```

### 2. Parametrized Tests for Validation

```java
@ParameterizedTest
@CsvSource({
    "null, 'Input cannot be null'",
    "'', 'Input cannot be empty'",
    "'@invalid', 'Invalid format'"
})
void validate_invalidInput_throwsException(String input, String expectedMessage) {
    ValidationException ex = assertThrows(ValidationException.class,
        () -> validator.validate(input));
    assertEquals(expectedMessage, ex.getMessage());
}
```

### 3. Error Path Testing

```java
@Test
void retry_maxAttemptsExceeded_throwsException() {
    // Simulate failures
    when(service.call()).thenThrow(new ServiceException());

    // Verify exception thrown after max retries
    assertThrows(RetryExhaustedException.class,
        () -> retryHandler.execute(() -> service.call()));

    // Verify attempted correct number of times
    verify(service, times(5)).call();
}
```

---

## Results from Real Project

This planning approach was used in the common-api-gateway project:

- **Starting**: 71.02% instructions, 56.61% branches
- **After 3 weeks**: 74.81% instructions, 61.71% branches
- **Gain**: +3.79% instructions, +5.10% branches
- **Tests added**: 500+ lines across 6 new test files
- **Key insight**: Discovered 61 integration tests covering classes with "0% unit coverage"

**Outcome**: Accepted 74.81% unit + comprehensive integration tests as well-tested codebase

---

## Next Steps

1. **Review this plan** with your team
2. **Adjust priorities** based on your domain knowledge
3. **Start Phase 1** - pick the first target class
4. **Use the skill guidance** in `jvm-test-quality.md` for test patterns
5. **Track progress** with `jacoco-compare.py`
6. **Celebrate wins** after each phase!

---

**Generated by**: Claude Code using jvm-test-quality skill
**Date**: 2026-01-08
**Skill Version**: 1.0.0
