# Example 1: Behavioral Verification

## Problem: Execution-Only Test

This test executes code but doesn't verify behavior:

```java
@Test
void testProcessRequest() {
    // ❌ BAD: Just executes code, doesn't verify behavior
    Request request = new Request("test");

    StepVerifier.create(service.processRequest(request))
        .verifyComplete();  // Only checks it completed, not WHAT happened
}
```

**Issues:**
- No verification of what the method actually did
- Doesn't prove short-circuit behavior
- Doesn't verify mock interactions
- Code coverage increases but quality doesn't

---

## Solution: Behavioral Verification

This test verifies actual behavior with proof:

```java
@Test
void testProcessRequest_whenCached_thenShortCircuits() {
    // ✅ GOOD: Verifies behavior with proof
    Request request = new Request("test");
    when(cache.get("test")).thenReturn(Mono.just(cachedResponse));

    StepVerifier.create(service.processRequest(request))
        .expectNext(cachedResponse)  // Verifies correct response returned
        .verifyComplete();

    // PROVE short-circuit behavior: expensive operation never called
    verifyNoInteractions(expensiveDownstreamService);
    verify(cache, times(1)).get("test");  // Verify cache was checked
}
```

**Improvements:**
- ✅ Verifies correct response returned (`expectNext`)
- ✅ Proves short-circuit behavior (`verifyNoInteractions`)
- ✅ Validates cache interaction
- ✅ Test name describes behavior, not just method name

---

## Pattern: Always Prove Behavior

### Bad Pattern
```java
StepVerifier.create(result).verifyComplete();
```

### Good Pattern
```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

StepVerifier.create(result)
    .assertNext(response -> {
        assertEquals("SUCCESS", response.getStatus());
        assertFalse(response.getData().isEmpty());
    })
    .verifyComplete();

// Prove the behavior you care about
verify(mockService, times(1)).callDownstream();
```

---

## Real-World Impact

**Before (execution-only):**
- 85% line coverage
- Bug: Service called downstream even when cached
- Test passed ✅ (but bug existed!)

**After (behavioral verification):**
- 85% line coverage (same)
- Bug: Caught by `verifyNoInteractions` assertion
- Test failed ❌ (correctly!)
- Bug fixed, test now passes ✅

**Lesson:** Coverage percentage isn't enough. Behavior verification catches bugs.
