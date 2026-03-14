---
name: jvm-test-quality
description: Improve JVM test quality and code coverage using behavioral verification, coverage analysis, and coverage tracking. Use for analyzing coverage gaps, improving branch coverage, creating test improvement plans, or preventing coverage regressions in Java/Kotlin/Scala projects. Supports service tier-based coverage goals (Tier 0→90%, Tier 1→85%, Tier 2→80%, Tier 3→75%, Tier 4→70%).
model: minimax-m2.5
license: Internal Use Only - Expedia Group
compatibility:
  languages: [Java 8+, Kotlin 1.5+, Scala 2.x/3.x, Groovy 3.x+]
  frameworks: [JUnit 5, JUnit 4, TestNG, Spock, ScalaTest]
  build-tools: [Maven 3.x, Gradle 6.x+, SBT 1.x]
  coverage-tools: [JaCoCo 0.8.x+ (Java/Kotlin), Scoverage 1.4.x+ (Scala)]
metadata:
  version: 1.4.0 # x-release-please-version
  author: Expedia Group
  category: testing
  tags: [java, kotlin, scala, testing, coverage, jacoco, scoverage, junit, scalatest, quality, tdd, ci-cd, behavioral-verification]
allowed-tools:
  - Read
  - Grep
  - Edit
  - Write
  - Bash
  - Task
argument-hint: "[analyze|improve|track|validate] [--tier 0|1|2|3|4]"
---

# JVM Test Quality Skill

Expert guidance for improving test coverage and quality in JVM projects (Java, Kotlin, Scala, Groovy).

## Dynamic Context Injection

**IMPORTANT**: When this skill is invoked, follow this order:
1. **Confirm tier** (if not specified in arguments) - see [Tier Confirmation](#tier-confirmation)
2. **Gather project context** (details below)
3. **Execute subcommand** with confirmed tier and gathered context

### Required Context (gather in parallel)
1. **Build System Detection**:
   - Check for `pom.xml` (Maven) or `build.gradle`/`build.gradle.kts` (Gradle) or `build.sbt` (SBT)
   - Extract project name, version, dependencies

2. **Coverage Tool Detection**:
   - **JaCoCo** (Java/Kotlin): Check for `jacoco-maven-plugin` or `jacoco` task in Gradle
   - **Scoverage** (Scala): Check for `scoverage-maven-plugin` or `sbt-scoverage` plugin
   - Scala projects use Scoverage, Java/Kotlin projects use JaCoCo

3. **Coverage Report Location** (check in order, use first found):
   - **JaCoCo:**
     - Maven: `target/site/jacoco/index.html`
     - Gradle: `build/reports/jacoco/test/html/index.html`
     - Gradle (multi-module): `build/jacocoHtml/index.html`
   - **Scoverage:**
     - Maven (multi-module): `target/cobertura.xml`
     - Maven (single module): `target/scoverage-report/cobertura.xml`
     - SBT: `target/scala-<version>/scoverage-report/cobertura.xml`
     - Note: Use cobertura.xml (Cobertura-compatible format), not scoverage.xml (native format)

4. **Test Framework Detection** (check dependencies):
   - JUnit 5 (Jupiter): `junit-jupiter-api`, `@Test` with `org.junit.jupiter`
   - JUnit 4: `junit`, `@Test` with `org.junit`
   - TestNG: `testng`, `@Test` with `org.testng`
   - Spock: `spock-core`, class names ending in `Spec`
   - ScalaTest: `scalatest`, class names ending in `Spec` or `Test`

5. **Test Directory Structure**:
   - Maven: `src/test/java`, `src/test/kotlin`, `src/test/scala`
   - Gradle: `src/test/java`, `src/test/kotlin`, `src/test/groovy`
   - SBT: `src/test/scala`

6. **Current Coverage** (if report exists):
   - JaCoCo: Read HTML report summary (line %, branch %, complexity %)
   - Scoverage: Read XML report (line-rate, branch-rate)
   - Note report generation timestamp

### Context Template
Once gathered, include this summary in your response:
```
📊 Project Context:
- Build: [Maven/Gradle] [version]
- Framework: [JUnit 5/TestNG/Spock]
- Report: [path] (generated: [timestamp])
- Current: [X%] line, [Y%] branch, [Z%] complexity
- Tier Goal: [Tier N] - [X%] line, [Y%] branch target
```

### If Context Gathering Fails
- Report location not found → Suggest appropriate command based on build tool:
  - Maven (Java/Kotlin): `mvn test jacoco:report`
  - Maven (Scala): `mvn test scoverage:report`
  - Gradle: `./gradlew test jacocoTestReport`
  - SBT: `sbt clean coverage test coverageReport`
- Build file not found → Ask user to confirm they're in project root
- Continue with skill execution using defaults

## Overview

This skill provides proven patterns for writing high-quality tests that verify behavior (not just execute code) and systematically improving code coverage.

**Supported Coverage Tools:**
- **JaCoCo** - Java and Kotlin projects (Maven/Gradle)
- **Scoverage** - Scala projects (Maven/SBT)

**Key Principles:**
- **Behavioral verification** over execution testing
- **Strategic targeting** (branches > error paths > edge cases)
- **Understanding limitations** (coverage metrics ≠ integration tests)
- **When NOT to force unit tests** (some code needs integration tests)
- **Coverage tracking** to prevent regressions
- **Service tier-based goals** (Tier 0→90%, Tier 1→85%, Tier 2→80%, Tier 3→75%, Tier 4→70%)

## Using This Skill with Claude Code

Invoke this skill using slash commands:

```bash
# Analyze coverage and create improvement plan
/jvm-test-quality analyze --tier 2

# Create tests for specific class
/jvm-test-quality improve PaymentProcessor.java

# Track coverage changes
/jvm-test-quality track --tier 1

# Validate test quality
/jvm-test-quality validate
```

See [Usage](#usage) section for complete command reference.

## Service Tier Coverage Goals

Coverage expectations vary by service criticality. See [TIER_GUIDE.md](references/TIER_GUIDE.md) for complete tier definitions.

| Tier | Line Coverage | Branch Coverage | Examples |
|------|---------------|-----------------|----------|
| **0** | 90% | 80% | Payment processing, PII handling |
| **1** | 85% | 75% | Authentication, billing |
| **2** | 80% | 70% | Order management (default) |
| **3** | 75% | 65% | Notifications, caching |
| **4** | 70% | 60% | Logging, metrics |

Specify tier with `--tier N` flag. Default: Tier 2 (80% goal).

## Tool Restrictions by Subcommand

To ensure safety and optimize performance, each subcommand has specific tool access:

| Subcommand | Allowed Tools | Rationale |
|------------|---------------|-----------|
| `analyze` | Read, Grep, Task(Explore), Bash | Report generation and parsing via script; saves baseline as side effect |
| `improve` | Read, Grep, Edit, Write, Bash(python3) | Needs structured coverage data to auto-select targets |
| `track` | Bash(python3), Read | Runs coverage comparison script |
| `validate` | Read, Grep | Read-only validation of test quality |

**Implementation Note**: While the skill has access to all tools defined in the frontmatter, Claude should self-restrict based on the subcommand being executed. For example, `analyze` should never Write or Edit files.

## Coverage Data Bootstrap

**Applies to**: `analyze`, `improve`, `track` (not `validate`)

Before executing its main workflow, every subcommand (except `validate`) MUST run this preamble:

1. **Detect coverage tool**: Determine if project uses JaCoCo or Scoverage
   - Check for `scoverage-maven-plugin`, `sbt-scoverage`, or Scala source directories → Scoverage
   - Otherwise → JaCoCo

2. **Resolve script path**: Use the skill's base directory to build absolute path:
   - JaCoCo: `<skill-base-dir>/scripts/jacoco-compare.py`
   - Scoverage: `<skill-base-dir>/scripts/scoverage-compare.py`
   - Never reference scripts relative to the target project

3. **Check for existing baseline**: Look for baseline file in project root:
   - JaCoCo: `.jacoco-baseline.json`
   - Scoverage: `.scoverage-baseline.json`

4. **If baseline exists**: Read it. Structured coverage data (instructions, branches, complexity, lines, methods) is available.

5. **If baseline does not exist**:
   a. Auto-discover coverage report (check paths from Dynamic Context Injection above)
   b. If report found: run appropriate script with `--save-baseline`:
      - JaCoCo: `python3 <skill-base-dir>/scripts/jacoco-compare.py --report <path> --save-baseline`
      - Scoverage: `python3 <skill-base-dir>/scripts/scoverage-compare.py --report <path> --save-baseline`
   c. Print: "No baseline found. Created baseline from current report."
   d. If no report found: **run** the appropriate command to generate the report:
      - Maven+JaCoCo: `mvn test jacoco:report`
      - Maven+Scoverage: `mvn test scoverage:report`
      - Gradle+JaCoCo: `./gradlew test jacocoTestReport`
      - SBT+Scoverage: `sbt clean coverage test coverageReport`
      - Set `JAVA_HOME` or other environment variables if the user has provided them
      - After report generation succeeds, continue to step 5b (save baseline) and proceed with the subcommand

6. **Coverage data available**: Subcommand proceeds with structured metrics from baseline file.

## Workflow

### What it does:
1. **Gathers context** - Detects build system, test framework, JaCoCo report location
2. **Analyzes coverage** - Identifies low-coverage classes with business logic
3. **Checks existing tests** - Looks for integration tests that may cover "0% unit coverage" classes
4. **Ranks targets** - Prioritizes by impact/effort ratio and service tier goals
5. **Generates plan** - Creates phased improvement plan with specific recommendations

### Tools Used:
- **Read** - Read JaCoCo reports, source files, test files
- **Grep** - Search for test patterns, integration tests
- **Task(Explore)** - Explore codebase for coverage analysis
- **Edit/Write** - Create/modify test files (improve subcommand only)
- **Bash(python3)** - Run jacoco-compare.py script (analyze, improve, track subcommands)

## Examples

Complete working examples:
- **[examples/00-complete-workflow.md](./examples/00-complete-workflow.md)** - Full coverage improvement plan workflow (68% → 85%)
- **[examples/01-behavioral-verification.md](./examples/01-behavioral-verification.md)** - Behavioral testing patterns
- **[examples/02-parametrized-tests.md](./examples/02-parametrized-tests.md)** - Parametrized test examples
- **[examples/03-clear-assertion-messages.md](./examples/03-clear-assertion-messages.md)** - Clear assertion message patterns

## Command Routing & Guardrails

### Smart Routing (no subcommand provided)

When invoked as `/jvm-test-quality` without a subcommand, detect project state and route automatically:

1. **No baseline and no coverage report** → Tell user to run tests with coverage first
   - Check for both `.jacoco-baseline.json` (Java/Kotlin) and `.scoverage-baseline.json` (Scala)
   - Check for JaCoCo reports (`target/site/jacoco/index.html`, `build/reports/jacoco/test/html/index.html`, etc.) and Scoverage reports (`target/cobertura.xml`, etc.)
2. **Coverage report exists but no baseline** → Route to `analyze` (first-time setup)
3. **Baseline exists and is recent** → Route to `improve` (continue improving)
4. **Baseline exists but is stale** (>7 days old or test files changed since) → Route to `track` (check progress)

Always print which subcommand was auto-selected and why: *"No subcommand specified. Detected coverage report without baseline → running `analyze`."*

### Tier Confirmation

**CRITICAL: Confirm tier BEFORE any context gathering or analysis work.**

When `--tier` is not specified, default to Tier 2 (80% goal) but **always confirm with the user IMMEDIATELY**:
- Ask tier confirmation as the FIRST action after subcommand routing
- DO NOT run tests, gather context, or analyze reports before confirmation
- Prompt: *"No tier specified. Defaulting to Tier 2 (80% line / 70% branch). Is this correct for your service, or should I use a different tier?"*
- Accept confirmation or tier change before continuing
- Exception: if a prior `analyze` in the same session already confirmed the tier, reuse it silently

**Workflow order:**
1. Route to subcommand (or auto-detect)
2. **Confirm tier** (if not specified)
3. Proceed with context gathering and analysis

### Subcommand Guardrails

Each subcommand validates prerequisites before executing:

| Subcommand | Guardrail |
|------------|-----------|
| `analyze` | If JaCoCo report missing → suggest running tests with coverage, stop |
| `improve` | If target class is a DTO/POJO/config → warn: "This class has minimal logic. Writing unit tests adds little value. Continue anyway?" |
| `improve` | If no class specified and all classes are above tier goal → inform user: "All classes meet tier goal. Consider `validate` to check test quality instead." |
| `track` | If baseline and current are identical → inform: "No coverage changes detected since baseline." |
| `validate` | If no test files found in specified path → inform and suggest correct path |

## Usage

Invoke this skill with `/jvm-test-quality <subcommand>`:

**Available Subcommands:**
- **`analyze`** - Analyze coverage reports and create multi-phase improvement plan
- **`improve`** - Create tests for specific class (or auto-select highest-impact target)
- **`track`** - Track coverage changes and prevent regressions
- **`validate`** - Validate test quality (detect execution-only tests, redundancy)

**Quick Examples:**
```bash
/jvm-test-quality analyze --tier 2          # Analyze and create plan
/jvm-test-quality improve Calculator.java    # Create tests for class
/jvm-test-quality track --save-baseline      # Save coverage baseline
/jvm-test-quality validate src/test/         # Check test quality
```

See [references/USAGE.md](references/USAGE.md) for detailed command reference with workflows, examples, and CI/CD integration.

---

## Key Best Practices

See [references/reference.md](references/reference.md) for comprehensive patterns (parametrized tests, assertion messages, reactive testing, helper methods).

**Core principles**: Behavioral verification over execution testing | Strategic targeting (branches > error paths > edge cases) | JaCoCo doesn't measure integration tests | >5 mocks = use integration test instead

## Coverage Tracking Scripts

Script locations (resolve from skill's base directory):
- **JaCoCo**: `<skill-base-dir>/scripts/jacoco-compare.py` — For Java/Kotlin projects
- **Scoverage**: `<skill-base-dir>/scripts/scoverage-compare.py` — For Scala projects
- **Shared Library**: `<skill-base-dir>/scripts/coverage_common.py` — Common utilities

See [scripts/README.md](scripts/README.md) for full usage, CI/CD integration, and manual baseline configuration.

---

## Continuous Improvement Plan

Use this phased approach to incrementally reach your tier coverage target. Each phase builds on the previous one.

### Phase 1: Baseline & Triage
- Run `/jvm-test-quality analyze --tier N` to establish current state
- Fix test discovery issues first (Step 0 findings)
- Identify integration tests covering "0% unit coverage" classes
- Accept integration-tested classes as covered (adjust expectations)
- **Exit criteria**: Accurate baseline, test discovery working

### Phase 2: Quick Wins (target: +5-10% coverage)
- Run `/jvm-test-quality improve` (auto-selects highest-impact target)
- Focus on classes with high gap%, low complexity (easy to test)
- Add missing assertions to execution-only tests (`/jvm-test-quality validate`)
- Run `/jvm-test-quality track` after each batch of improvements
- **Exit criteria**: Coverage trending up, no regressions

### Phase 3: Core Coverage (target: within 10% of tier goal)
- Target business-critical classes with moderate complexity
- Use parametrized tests for input-heavy methods
- Add branch coverage for conditional logic (if/else, switch, ternary)
- Track per-class progress with `/jvm-test-quality track`
- **Exit criteria**: Within 10% of tier line coverage goal

### Phase 4: Gap Closing (target: reach tier goal)
- Target remaining high-gap classes
- Focus on error paths and edge cases
- Add reactive test patterns (StepVerifier) where applicable
- Run `/jvm-test-quality validate` to ensure test quality, not just quantity
- **Exit criteria**: Tier coverage goals met

### Phase 5: Sustain
- Integrate `/jvm-test-quality track` into CI pipeline
- Block merges that decrease coverage below tier threshold
- Run `/jvm-test-quality validate` periodically to maintain test quality
- Re-assess tier classification annually per governance requirements

### Phase Targets by Tier

| Tier | Start → Phase 2 | Phase 3 | Phase 4 (Goal) |
|------|-----------------|---------|-----------------|
| 0    | +10% toward 90% | 80%+    | 90% line, 80% branch |
| 1    | +10% toward 85% | 75%+    | 85% line, 75% branch |
| 2    | +10% toward 80% | 70%+    | 80% line, 70% branch |
| 3    | +10% toward 75% | 65%+    | 75% line, 65% branch |
| 4    | +10% toward 70% | 60%+    | 70% line, 60% branch |

---

## Real-World Results

Validated across 3 production projects:
- **common-api-gateway** (Java): 58% → 74% line (+16pp) | [PR #874](https://github.com/eg-internal/common-api-gateway/pull/874), [#875](https://github.com/eg-internal/common-api-gateway/pull/875)
- **mls-txef** (Scala): 93% → 94% line | [PR #974](https://github.com/eg-internal/mls-txef/pull/974)
- **mls-txef-publisher** (Scala): 84% → 86% line (+2pp) | [PR #346](https://github.com/eg-internal/mls-txef-publisher/pull/346)

**See**: [references/CASE_STUDIES.md](references/CASE_STUDIES.md) for detailed case studies

## References

- [references/CASE_STUDIES.md](references/CASE_STUDIES.md) — Real-world validation with PR links and techniques
- [references/USAGE.md](references/USAGE.md) — Detailed command reference with workflows and examples
- [references/reference.md](references/reference.md) — Best practices guide (540 lines)
- [references/TIER_GUIDE.md](references/TIER_GUIDE.md) — Service tier classification guide
- [references/ARCHITECTURE.md](references/ARCHITECTURE.md) — Design decisions and parser architecture
- [examples/00-complete-workflow.md](./examples/00-complete-workflow.md) — End-to-end workflow
- [scripts/README.md](./scripts/README.md) — Script docs and CI/CD integration
