# Example 2: Parametrized Tests

## Problem: Redundant Test Methods

Multiple nearly-identical tests for different inputs:

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

@Test
void testValidateEmptyString() {
    // ❌ BAD: Redundant test method
    ValidationException exception = assertThrows(ValidationException.class,
        () -> validator.validate(""));
    assertEquals("Input cannot be blank", exception.getMessage());
}

@Test
void testValidateWhitespace() {
    // ❌ BAD: Duplicate logic, different input
    ValidationException exception = assertThrows(ValidationException.class,
        () -> validator.validate("   "));
    assertEquals("Input cannot be blank", exception.getMessage());
}

@Test
void testValidateTab() {
    // ❌ BAD: Yet another duplicate
    ValidationException exception = assertThrows(ValidationException.class,
        () -> validator.validate("\t"));
    assertEquals("Input cannot be blank", exception.getMessage());
}

@Test
void testValidateNewline() {
    // ❌ BAD: Fourth duplicate!
    ValidationException exception = assertThrows(ValidationException.class,
        () -> validator.validate("\n"));
    assertEquals("Input cannot be blank", exception.getMessage());
}
```

**Issues:**
- 4 test methods, all doing the same thing
- 24 lines of code with high duplication
- Hard to maintain (change assertion = 4 places to update)
- Adds noise to test reports

---

## Solution: Parametrized Test

One test method with multiple inputs:

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

@ParameterizedTest
@ValueSource(strings = {"", "   ", "\t", "\n"})
void testValidateRejectsBlankInput(String input) {
    // ✅ GOOD: Single test, multiple inputs
    ValidationException exception = assertThrows(ValidationException.class,
        () -> validator.validate(input));
    assertEquals("Input cannot be blank", exception.getMessage());
}
```

**Improvements:**
- ✅ 1 test method instead of 4
- ✅ 6 lines instead of 24 (75% reduction)
- ✅ Single source of truth for assertion
- ✅ Easy to add more inputs (just add to `@ValueSource`)
- ✅ Clear intent: "rejects blank input" (not "empty", "whitespace", etc.)

---

## Advanced: CSV Source for Complex Data

```java
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

// ❌ BAD: Multiple redundant tests
@Test
void testAgeValidation_minor() {
    assertFalse(validator.validateAge(17));
}

@Test
void testAgeValidation_adult() {
    assertTrue(validator.validateAge(18));
}

@Test
void testAgeValidation_senior() {
    assertTrue(validator.validateAge(65));
}

@Test
void testAgeValidation_invalid() {
    assertFalse(validator.validateAge(-1));
}
```

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

// ✅ GOOD: Single parametrized test with CSV data
@ParameterizedTest
@CsvSource({
    "17, false",   // Minor
    "18, true",    // Adult
    "65, true",    // Senior
    "-1, false",   // Invalid
    "0, false",    // Edge case
    "150, false"   // Unrealistic
})
void testAgeValidation(int age, boolean expected) {
    assertEquals(expected, validator.validateAge(age));
}
```

---

## Pattern: When to Use Parametrized Tests

### Use Parametrized Tests When:
- ✅ Multiple inputs produce same behavior
- ✅ Testing boundary conditions (0, -1, max, min)
- ✅ Testing different formats of same concept (empty, whitespace, null)
- ✅ Testing validation rules across different values

### Don't Use Parametrized Tests When:
- ❌ Each input requires different setup/mocking
- ❌ Each input produces different behavior (not just different output)
- ❌ Assertions are different for each input
- ❌ Only 1-2 test cases (overhead not worth it)

---

## Real-World Impact

**Project: common-api-gateway**

**Before:**
- 47 validation tests across 3 test files
- 420 lines of test code
- Difficult to identify missing edge cases

**After:**
- 12 parametrized tests
- 180 lines of test code (57% reduction)
- Clear coverage of all edge cases
- Added 15 new edge cases that were previously missed

**Lesson:** Parametrized tests reduce duplication AND improve coverage by making it easy to add cases.
