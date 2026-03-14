# JVM Test Quality - Command Reference

Detailed usage guide for all jvm-test-quality subcommands.

## Command Overview

```bash
/jvm-test-quality <subcommand> [options]
```

**Subcommands:**
- `analyze` - Analyze coverage and create improvement plan
- `improve` - Create tests for specific class
- `track` - Track coverage changes against baseline
- `validate` - Validate test quality

## `/jvm-test-quality analyze`

Analyze JaCoCo/Scoverage coverage reports and identify improvement opportunities.

**Tools Used**: Read, Grep, Task(Explore), Bash(python3)

**What it does:**
- Verifies tests actually ran (catches broken test discovery)
- Parses coverage report via appropriate script (auto-discovers location)
- Applies tier-based coverage goals (Tier 0→90%, Tier 1→85%, Tier 2→80%, Tier 3→75%, Tier 4→70%)
- Identifies classes below tier threshold
- Filters out POJOs, generated code, simple data classes
- Checks for existing integration tests
- Ranks classes by impact/effort ratio
- Generates phased improvement plan
- Saves baseline as side effect for subsequent `track`/`improve` calls

**Workflow:**
0. **Tier Confirmation**: If `--tier` not specified, confirm tier with user BEFORE any analysis
1. **Test Execution Check**: Before coverage analysis, verify tests actually ran:
   - Gradle: Read `build/reports/tests/test/index.html`, extract test count
   - Maven: Check `target/surefire-reports/` for `.xml` result files
   - Count test source files (`*Test.java`, `*Spec.groovy`, `*Spec.scala`, etc.) in `src/test/`
   - If executed tests << test source files, flag as **primary issue** (broken test discovery) before proceeding
2. **Coverage Data Bootstrap**: Follow Coverage Data Bootstrap preamble from SKILL.md
3. **Report Parsing**: Extract per-class coverage data from coverage reports
4. **Gap Analysis**: Compare current coverage vs tier goal for each class
5. **Filtering**: Exclude POJOs, DTOs, config classes, generated code
6. **Integration Check**: Search for `@SpringBootTest`, `@WebMvcTest` covering low-coverage classes
7. **Prioritization**: Rank by: (gap% × class_LOC) / estimated_effort
8. **Plan Generation**: Create 3-5 phases with specific targets
9. **Refresh Baseline**: Run appropriate compare script with `--save-baseline` to ensure baseline reflects latest data

**Examples:**
```bash
# Regulatory/Critical service (90% coverage goal)
/jvm-test-quality analyze --tier 0

# Mission-critical service (85% coverage goal)
/jvm-test-quality analyze --tier 1

# Core business logic (80% coverage goal) - DEFAULT
/jvm-test-quality analyze --tier 2
/jvm-test-quality analyze    # Same as tier 2

# Supporting service (75% coverage goal)
/jvm-test-quality analyze --tier 3

# Infrastructure (70% coverage goal)
/jvm-test-quality analyze --tier 4

# With specific report path (JaCoCo)
/jvm-test-quality analyze --tier 2 --report target/site/jacoco/index.html

# With specific report path (Scoverage)
/jvm-test-quality analyze --tier 2 --report target/cobertura.xml
```

**Output**: Multi-phase improvement plan with 3-5 high-impact targets per phase, showing:
- Current coverage vs tier goal
- Classes below tier threshold
- Recommended approach (unit vs integration tests)
- Estimated effort per class

---

## `/jvm-test-quality improve`

Create tests for a specific class based on best practices.

**Tools Used**: Read, Grep, Edit, Write, Bash(python3)

**What it does:**
- Auto-selects highest-impact target when no class specified
- Analyzes the class structure
- Identifies untested branches, error paths, edge cases
- Suggests test design pattern (parametrized, helper methods, etc.)
- Provides test template with behavioral verification
- Considers reactive patterns if applicable (StepVerifier)

**Workflow:**
1. **Coverage Data Bootstrap**: Follow Coverage Data Bootstrap preamble from SKILL.md
2. **Target Selection** (if no class specified):
   - Read coverage baseline for overall metrics
   - Parse package-level reports for per-class coverage
   - Rank classes by impact: `(gap% × class_LOC) / estimated_effort`
   - Filter out POJOs, DTOs, config classes, generated code
   - Auto-select highest-impact class; print selection with rationale
   - User can override by specifying a class name
3. **Class Analysis**: Read target class, identify methods, branches, dependencies
4. **Existing Test Check**: Search for existing test file, check what's already covered
5. **Coverage Gap Identification**:
   - Untested branches (if/else, ternary, switch)
   - Error paths (exceptions, null handling, onError callbacks)
   - Edge cases (boundary conditions, empty collections)
6. **Pattern Selection**:
   - Parametrized tests for multiple inputs
   - Helper methods for repeated assertions
   - Mock strategy (constructor injection vs field injection)
7. **Test Generation**: Create/update test file with:
   - Behavioral verification (not just code execution)
   - Clear test names (given_when_then format)
   - Clear assertion messages (JUnit 5 with descriptive messages)
8. **Reactive Check**: If class returns Mono/Flux, use StepVerifier patterns

**Examples:**
```bash
# Auto-select highest-impact uncovered class
/jvm-test-quality improve

# Specific class (Java)
/jvm-test-quality improve RateLimiter.java

# Specific class (Scala)
/jvm-test-quality improve TaxCalculator.scala

# With specific focus
/jvm-test-quality improve ValidationService.java --focus branches
```

**Output**: Test code with behavioral verification, parametrized tests where appropriate, and clear assertions.

---

## `/jvm-test-quality track`

Track coverage changes against baseline.

**Tools Used**: Bash(python3), Read

**What it does:**
- Runs appropriate compare script to compare current vs baseline coverage
- Applies tier-based coverage goals as targets
- Tracks 5 metrics: instructions, branches, complexity, lines, methods
- Shows +/- changes for each metric
- Fails if any metric decreases (prevents regressions)
- Warns if below tier threshold

**Workflow:**
1. **Coverage Data Bootstrap**: Follow Coverage Data Bootstrap preamble from SKILL.md (auto-creates baseline if missing)
2. **Baseline Management**:
   - If `--save-baseline`: Re-parse current report, overwrite baseline
   - If `--set-baseline X Y Z`: Create baseline with manual values
   - Otherwise: Use existing baseline (guaranteed to exist after bootstrap)
3. **Comparison**: Run appropriate compare script to diff current vs baseline
4. **Regression Detection**: Check if any metric decreased
5. **Tier Goal Check**: Compare against tier-specific targets
6. **Report Generation**: Show summary with +/- for each metric
7. **Exit Code**: Return 0 if no regressions, 1 if any metric decreased

**Examples:**
```bash
# Save current coverage as baseline (Tier 2 - default 80%)
/jvm-test-quality track --save-baseline --tier 2

# Save baseline for Tier 1 service (85% goal)
/jvm-test-quality track --save-baseline --tier 1

# Check for regressions against Tier 2 goal
/jvm-test-quality track --tier 2

# Check Tier 1 service (strictest requirements)
/jvm-test-quality track --tier 1

# Check Tier 4 infrastructure service
/jvm-test-quality track --tier 4

# Compare against specific baseline
/jvm-test-quality track --baseline .jacoco-baseline.json --tier 2
```

**Output**: Coverage comparison report with:
- Current coverage vs baseline
- Current coverage vs tier goal
- Pass/fail status (regression check)
- Recommendations to reach tier goal

---

## `/jvm-test-quality validate`

Validate test quality based on best practices.

**Tools Used**: Read, Grep

**What it does:**
- Checks for behavioral verification (not just `.verifyComplete()`)
- Identifies redundant tests
- Finds tests that execute code without assertions
- Suggests improvements based on best practices

**Workflow:**
1. **Test Discovery**: Find all test files in specified directory/file
2. **Quality Checks**:
   - **Behavioral Verification**: Detect tests with only `.verifyComplete()` and no assertions
   - **Assertion Presence**: Find test methods without any assertions (likely execution-only)
   - **Redundant Tests**: Identify duplicate test logic or multiple tests for same condition
   - **Naming Convention**: Check for descriptive test names (given_when_then format)
   - **Mock Overuse**: Flag tests with >5 mocks (candidate for integration test)
3. **Pattern Analysis**:
   - Parametrized test opportunities (multiple similar tests)
   - Helper method extraction (repeated assertion blocks)
   - Clear assertion message usage (descriptive vs vague messages)
4. **Report Generation**: Categorize issues by severity:
   - **Critical**: Tests without assertions, execution-only tests
   - **Warning**: Redundant tests, poor naming, mock overuse
   - **Suggestion**: Refactoring opportunities
5. **Recommendations**: Provide specific fixes for each issue

**Examples:**
```bash
# Check all tests in directory
/jvm-test-quality validate src/test/java/

# Check specific test file
/jvm-test-quality validate RateLimiterTest.java

# Check Scala tests
/jvm-test-quality validate src/test/scala/com/example/
```

**Output**: Quality report with recommendations categorized by severity.

---

## Command Routing & Guardrails

### Smart Routing (no subcommand provided)

When invoked as `/jvm-test-quality` without a subcommand, detect project state and route automatically:

1. **No baseline and no coverage report** → Tell user to run tests with coverage first
   - Check for both `.jacoco-baseline.json` (Java/Kotlin) and `.scoverage-baseline.json` (Scala)
   - Check for JaCoCo reports and Scoverage reports (see SKILL.md for full path list)
2. **Coverage report exists but no baseline** → Route to `analyze` (first-time setup)
3. **Baseline exists and is recent** → Route to `improve` (continue improving)
4. **Baseline exists but is stale** (>7 days old or test files changed since) → Route to `track` (check progress)

Always print which subcommand was auto-selected and why:
*"No subcommand specified. Detected coverage report without baseline → running `analyze`."*

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
| `analyze` | If coverage report missing → suggest running tests with coverage, stop |
| `improve` | If target class is a DTO/POJO/config → warn: "This class has minimal logic. Writing unit tests adds little value. Continue anyway?" |
| `improve` | If no class specified and all classes are above tier goal → inform user: "All classes meet tier goal. Consider `validate` to check test quality instead." |
| `track` | If baseline and current are identical → inform: "No coverage changes detected since baseline." |
| `validate` | If no test files found in specified path → inform and suggest correct path |

---

## CI/CD Integration

### Using track in CI Pipeline

```bash
# In CI pipeline script (fails on regression)
python3 scripts/jacoco-compare.py

# Or for Scala projects
python3 scripts/scoverage-compare.py
```

Exit codes:
- `0` - All metrics maintained or improved
- `1` - One or more metrics decreased (regression)

### GitHub Actions Example

```yaml
- name: Check coverage
  run: |
    mvn test jacoco:report
    python3 tools/ai/claude/skills/jvm-test-quality/scripts/jacoco-compare.py
```

---

## See Also

- [SKILL.md](../SKILL.md) - Main skill documentation
- [reference.md](./reference.md) - Testing best practices and patterns
- [TIER_GUIDE.md](./TIER_GUIDE.md) - Service tier classification
- [../scripts/README.md](../scripts/README.md) - Coverage scripts documentation
