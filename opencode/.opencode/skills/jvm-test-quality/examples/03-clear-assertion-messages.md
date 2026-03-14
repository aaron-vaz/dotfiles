# Example 3: Clear Assertion Messages

## Problem: Vague Assertions with Poor Error Messages

Using assertions without descriptive messages:

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

@Test
void testGetUsers() {
    // ❌ BAD: Assertions without context
    List<User> users = service.getUsers();

    assertTrue(users.size() == 3);  // Failure: "expected true but was false"
    assertTrue(users.get(0).getName().equals("Alice"));  // Generic failure
    assertTrue(users.get(1).getAge() > 18);  // What was the actual age?
    assertNotNull(users.get(2).getEmail());  // No context on failure
}
```

**Failure Output:**
```
org.opentest4j.AssertionFailedError: expected: <true> but was: <false>
    at TestClass.testGetUsers(TestClass.java:42)
```

**Issues:**
- ❌ No information about actual values
- ❌ Hard to debug failures
- ❌ Can't see what was wrong without running debugger
- ❌ Requires looking at source code to understand what failed

---

## Solution: Descriptive Assertions with Messages

Use JUnit 5 assertions with descriptive messages:

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import java.util.List;

@Test
void testGetUsers() {
    // ✅ GOOD: Clear assertions with descriptive messages
    List<User> users = service.getUsers();

    assertEquals(3, users.size(),
        "Expected 3 users but got " + users.size());

    assertEquals("Alice", users.get(0).getName(),
        "First user should be Alice");

    assertTrue(users.get(1).getAge() > 18,
        () -> "Second user age should be > 18 but was " + users.get(1).getAge());

    assertNotNull(users.get(2).getEmail(),
        "Third user email should not be null");
}
```

**Improved Failure Output:**
```
org.opentest4j.AssertionFailedError: Expected 3 users but got 2
Expected :3
Actual   :2
    at TestClass.testGetUsers(TestClass.java:12)
```

**Improvements:**
- ✅ Clear failure messages with actual vs expected
- ✅ No debugger needed to understand failure
- ✅ Failures are self-documenting
- ✅ Uses supplier lambdas for expensive string operations

---

## Pattern: Assertion Message Best Practices

### Use Descriptive Messages

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

// ❌ BAD: No message
assertEquals(expected, actual);

// ✅ GOOD: Clear message
assertEquals(expected, actual, "Order status should be PENDING");

// ❌ BAD: Message doesn't add value
assertTrue(age > 18, "assertion failed");

// ✅ GOOD: Message provides context
assertTrue(age > 18, "User must be adult (>18) but age was " + age);
```

### Use Supplier Lambdas for Expensive Operations

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import java.util.stream.Collectors;

// ❌ BAD: Always builds expensive string even on success
assertEquals(expected, actual,
    "Failed with data: " + expensiveDebugInfo.stream()
        .map(Object::toString)
        .collect(Collectors.joining(", ")));

// ✅ GOOD: Only builds string if assertion fails
assertEquals(expected, actual,
    () -> "Failed with data: " + expensiveDebugInfo.stream()
        .map(Object::toString)
        .collect(Collectors.joining(", ")));
```

### Group Related Assertions

```java
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.junit.jupiter.api.Test;

@Test
void testUser() {
    User user = service.getUser(123);

    // ✅ GOOD: Execute all assertions, report all failures
    assertAll("user properties",
        () -> assertNotNull(user, "User should not be null"),
        () -> assertEquals("Alice", user.getName(), "Name should be Alice"),
        () -> assertEquals(25, user.getAge(), "Age should be 25"),
        () -> assertEquals("alice@example.com", user.getEmail(), "Email should match")
    );
}
```

**Benefits of assertAll:**
- Reports ALL failures, not just the first one
- Groups logically related assertions
- Makes test failures more informative

---

## Advanced: Complex Object Validation

### Bad: Multiple Independent Assertions

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

@Test
void testCreateOrder() {
    // ❌ BAD: Stops at first failure, hides other issues
    Order order = service.createOrder(request);

    assertNotNull(order);
    assertEquals("PENDING", order.getStatus());
    assertEquals(3, order.getItems().size());
    assertEquals("Product A", order.getItems().get(0).getName());
    assertEquals(100.0, order.getTotal(), 0.01);
    assertTrue(order.getCreatedAt().isBefore(Instant.now()));
}
```

**Problem**: If first assertion fails, you don't know about other failures.

### Good: Grouped Assertions

```java
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.List;

@Test
void testCreateOrder() {
    // ✅ GOOD: All assertions execute, all failures reported
    Order order = service.createOrder(request);

    assertAll("order validation",
        () -> assertNotNull(order, "Order should not be null"),
        () -> assertEquals("PENDING", order.getStatus(),
            "New order should have PENDING status"),
        () -> assertEquals(3, order.getItems().size(),
            "Order should have 3 items"),
        () -> assertEquals("Product A", order.getItems().get(0).getName(),
            "First item should be Product A"),
        () -> assertEquals(100.0, order.getTotal(), 0.01,
            "Order total should be $100.00"),
        () -> assertTrue(order.getCreatedAt().isBefore(Instant.now()),
            "Order creation time should be in the past")
    );
}
```

**Failure Output:**
```
org.opentest4j.MultipleFailuresError: order validation (2 failures)
    Expected :PENDING
    Actual   :DRAFT

    Expected :3
    Actual   :2
```

---

## Pattern: Collection Assertions

### Checking Collection Contents

```java
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import java.util.List;

@Test
void testCollectionContents() {
    List<String> items = List.of("apple", "banana", "cherry");

    assertAll("list validation",
        () -> assertEquals(3, items.size(), "List should have 3 items"),
        () -> assertTrue(items.contains("apple"), "List should contain apple"),
        () -> assertEquals("banana", items.get(1), "Second item should be banana"),
        () -> assertEquals(List.of("apple", "banana", "cherry"), items,
            "List contents should match expected")
    );
}
```

### Checking Empty Collections

```java
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import java.util.List;

@Test
void testEmptyList() {
    List<String> items = service.getEmptyList();

    assertTrue(items.isEmpty(),
        () -> "List should be empty but contained " + items.size() + " items: " + items);
}
```

---

## Kotlin: Using kotlin-test

For Kotlin tests, use kotlin-test for idiomatic assertions:

```kotlin
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.test.assertContains

class UserServiceTest {
    @Test
    fun `should return three users`() {
        val users = service.getUsers()

        assertEquals(3, users.size, "Expected 3 users")
        assertEquals("Alice", users[0].name, "First user should be Alice")
        assertTrue(users[1].age > 18, "Second user should be adult")
        assertNotNull(users[2].email, "Third user should have email")
    }

    @Test
    fun `should contain expected user`() {
        val users = service.getUsers()
        val names = users.map { it.name }

        assertContains(names, "Alice", "Users should include Alice")
    }
}
```

**Kotlin-test benefits:**
- No reflection (compile-time safe)
- Idiomatic Kotlin syntax
- Good error messages
- Multiplatform support

---

## Real-World Impact

**Project: common-api-gateway**

**Before:**
- Generic assertions without messages
- First failure hides subsequent issues
- 30% of test failures required debugger to understand

**After:**
- Descriptive messages on all assertions
- `assertAll` groups related checks
- 95% of failures are clear from output alone

**Lesson:** Good assertion messages are documentation. They help future developers (including yourself) understand failures instantly.

---

## Summary: No Reflection Needed

**JUnit 5 provides everything you need:**
- ✅ Clear assertions with custom messages
- ✅ `assertAll` for grouped assertions
- ✅ Supplier lambdas for expensive operations
- ✅ No reflection overhead
- ✅ Compile-time safety
- ✅ Standard library (no extra dependencies)

**For Kotlin:**
- ✅ kotlin-test provides idiomatic assertions
- ✅ Also reflection-free
- ✅ Multiplatform compatible

**Avoid reflection-based assertion libraries:**
- ❌ Runtime overhead from reflection
- ❌ Can break with Java modules/sealed classes
- ❌ Extra dependency to maintain
- ❌ Not needed for clear test failures
