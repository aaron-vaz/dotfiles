---
name: jvm
description: Running builds, tests, or troubleshooting JVM projects using Gradle or Maven. Use when running builds, tests, encountering Java version errors, build failures, or when the user mentions Gradle, Maven, ./gradlew, mvn, or JVM projects.
model: minimax-m2.5
last_reviewed: 2026-02-26
---

# JVM Projects (Gradle & Maven)

Comprehensive guide for running JVM commands and troubleshooting build issues.

## Running Commands

Claude Code runs non-interactive bash, so jabba must be explicitly sourced. Use exact version strings (indexed 2026-03-11).

### Pattern
```bash
source ~/.jabba/jabba.sh && jabba use <exact-version> && <command>
```

### Examples
```bash
# Java 25 project
source ~/.jabba/jabba.sh && jabba use temurin@25 && ./gradlew build

# Java 21 project
source ~/.jabba/jabba.sh && jabba use temurin@21.0.8 && ./gradlew build

# Java 17 project
source ~/.jabba/jabba.sh && jabba use temurin@17.0.16 && ./gradlew test

# Java 11 legacy project
source ~/.jabba/jabba.sh && jabba use temurin@11.0.28 && mvn clean install
```

## Determining Java Version

Check these sources in order:

1. **Project AGENTS.md** - Look for "Java Version" or JDK requirements
2. **build.gradle.kts** - Check `java.toolchain.languageVersion` or `sourceCompatibility`
3. **pom.xml** - Check `<maven.compiler.source>` or `<java.version>`
4. **gradle.properties** - Check for Java version properties
5. **.java-version** - Some projects use this file

### Quick Check Commands
```bash
# Gradle - show Java toolchain
./gradlew -q javaToolchains

# Check build.gradle.kts for version
grep -E "languageVersion|sourceCompatibility" build.gradle.kts
```

## Available JDKs

Installed versions (last indexed 2026-03-11):
- `temurin@25` - Java 25 (e.g., egtnl-readout-api)
- `temurin@24.0.2` - Java 24
- `temurin@21.0.8` - Java 21 (latest LTS)
- `temurin@17.0.16` - Java 17 (LTS)
- `temurin@11.0.28` - Java 11 (legacy LTS)

## Troubleshooting

### Build Fails with Multiple Errors

**❌ Anti-pattern (do NOT do this):**
```
Fix error 1 → rebuild → fix error 2 → rebuild → ... (20-30 cycles, 1-2 hours wasted)
```

**✅ Correct pattern:**
```bash
# 1. Capture ALL errors at once
./gradlew build 2>&1 | tee build-errors.log

# 2. Categorize by type
grep "error:" build-errors.log | grep -v "^Note:"   # Compilation errors
grep "FAILED" build-errors.log                        # Test failures

# 3. Fix ALL in one pass (main + test code together)
# 4. Rebuild once to verify
./gradlew build
```

### Build Fails with Java Version Error

```bash
# Check current Java version
java -version

# Use correct JDK via jabba - use exact version strings
source ~/.jabba/jabba.sh && jabba use temurin@25 && ./gradlew build    # Java 25
source ~/.jabba/jabba.sh && jabba use temurin@21.0.8 && ./gradlew build  # Java 21
```

**Common cause:** Wrong Java version active. Check project AGENTS.md or build files for required version.

### Dependency Resolution Issues

```bash
# Clear Gradle cache and rebuild
./gradlew clean build --refresh-dependencies

# See dependency tree
./gradlew dependencies

# Find dependency conflicts
./gradlew dependencyInsight --dependency <name>
```

### Tests Not Running

```bash
# Force test re-run (skip cache)
./gradlew test --rerun-tasks

# Run with more output
./gradlew test --info

# Run specific test
./gradlew test --tests "com.example.MyTest.testMethod"
```

### Spotless/Formatting Fails

```bash
# Apply formatting fixes
./gradlew spotlessApply

# Check what would change
./gradlew spotlessCheck
```

### Build Cache Issues

```bash
# Clean everything
./gradlew clean
rm -rf ~/.gradle/caches/build-cache-*

# Or disable cache for one run
./gradlew build --no-build-cache
```

### Kotlin Compilation Issues

```bash
# Full rebuild with clean
./gradlew clean build

# Check Kotlin version
./gradlew kotlinDslPluginVersion
```

### jabba: command not found

Always source jabba first:
```bash
source ~/.jabba/jabba.sh && jabba use ...
```

### Bare version number not recognized (`jabba use 25`)

`jabba use 25` is not a valid identifier — bare numbers don't work.
Always use `vendor@version` format:
```bash
# WRONG
jabba use 25

# RIGHT
jabba use temurin@25
jabba use temurin@21.0.8
```

### No matching JDK found

Install the required version:
```bash
jabba install temurin@21.0.8
```

### Background Test Hook Uses Wrong Java Version

The async test hook runs `./gradlew test` without sourcing jabba. It uses whatever Java is on the system PATH. Projects requiring a different Java version will see errors like "Kotlin does not yet support X JDK target" or exit code 144 from background test notifications. These are hook infrastructure failures, not code issues. Always verify test results with an explicit jabba-sourced run.

## Debug Commands

```bash
# Build with stacktrace
./gradlew build --stacktrace

# Build with debug logging
./gradlew build --debug

# Build with scan (uploads to gradle.com)
./gradlew build --scan
```

## Java Code Style

### Use `final` Liberally

Apply `final` to all variables, parameters, and fields that won't be reassigned. This improves code clarity and prevents accidental mutations.

**Method parameters:**
```java
public void processData(final String input, final int threshold) {
    // Cannot reassign input or threshold
}
```

**Local variables:**
```java
public void example() {
    final String name = "test";
    final List<String> items = new ArrayList<>();
    items.add("foo");  // OK - modifying contents, not reassignment
    // name = "other";  // Compiler error
}
```

**Fields:**
```java
public class Example {
    private final String id;
    private final Logger logger = LoggerFactory.getLogger(Example.class);

    public Example(final String id) {
        this.id = id;
    }
}
```

**When to omit `final`:**
- Loop counters that increment: `for (int i = 0; i < n; i++)`
- Variables explicitly designed for reassignment (rare)
- Try-with-resources (implicit final)

**Benefits:**
- Documents intent - this value won't change
- Catches accidental reassignments at compile time
- Makes code easier to reason about
- Enables certain compiler optimizations

## Common Patterns

### Full Clean Build
```bash
source ~/.jabba/jabba.sh && jabba use temurin@21.0.8 && ./gradlew clean build --refresh-dependencies
```

### Run Tests with Coverage
```bash
source ~/.jabba/jabba.sh && jabba use temurin@21.0.8 && ./gradlew test jacocoTestReport
```

### Maven Equivalent
```bash
source ~/.jabba/jabba.sh && jabba use temurin@17.0.16 && mvn clean install -DskipTests
```
