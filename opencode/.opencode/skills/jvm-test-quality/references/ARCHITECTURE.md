# Coverage Parser Architecture

## Problem

The jvm-test-quality skill currently only supports JaCoCo (Java/Kotlin), but claims to support Scala. Scala projects use Scoverage for coverage reporting. We need to extend support without duplicating code.

## Key Findings

1. **JaCoCo** generates HTML reports with coverage data embedded in tables
2. **Scoverage** generates both native XML and Cobertura-compatible XML reports
   - **scoverage.xml**: Native Scoverage format with percentage-based rates
   - **cobertura.xml**: Cobertura-compatible format with decimal rates (0.0-1.0) - **we use this**
3. Both tools track similar metrics: line/statement coverage, branch coverage, complexity
4. Baseline management, comparison logic, and CLI patterns are identical across tools

## Design Decision: Shared Library + Tool-Specific Parsers

### Architecture

```
scripts/
├── coverage_common.py         # Shared library (NEW)
│   ├── Baseline management (save/load)
│   ├── Comparison logic
│   ├── Percentage calculations
│   └── CLI argument parsing utilities
│
├── jacoco-compare.py          # JaCoCo-specific (REFACTORED)
│   └── JaCoCo HTML parser
│
├── scoverage-compare.py       # Scoverage-specific (NEW)
│   └── Cobertura XML parser
│
└── README.md                  # Documentation (UPDATED)
```

### Rationale

**Why shared library?**
- Baseline file format is identical (`.jacoco-baseline.json` / `.scoverage-baseline.json`)
- Comparison logic is identical (diff with tolerance, pass/fail)
- CLI patterns are identical (--save-baseline, --set-baseline, --tolerance)
- Reduces code duplication from ~200 lines per script to ~50 lines

**Why separate scripts?**
- Different input formats (HTML vs XML) require different parsers
- Clear separation of concerns
- Easier to maintain and test
- Follows colleague's suggestion
- Future tools (Clover, etc.) can add their own parser scripts

### Metrics Mapping

| Concept | JaCoCo | Scoverage (Cobertura XML) |
|---------|--------|---------------------------|
| Line coverage | Instructions | Line-rate |
| Branch coverage | Branches | Branch-rate |
| Complexity | Complexity | Complexity |
| Method coverage | Methods | Methods (in XML) |
| - | Lines | (Same as instructions) |
| Statement coverage | - | Statement (Scoverage-specific) |

**Baseline format (common):**
```json5
{
  "instructions": 75.5,  # JaCoCo: instructions; Scoverage: line-rate
  "branches": 60.0,      # JaCoCo: branches; Scoverage: branch-rate
  "complexity": 65.0,    # Both support
  "lines": 73.0,         # JaCoCo: lines; Scoverage: (same as line-rate)
  "methods": 70.0        # JaCoCo: methods; Scoverage: methods
}
```

### Coverage Tool Detection

The skill will auto-detect the coverage tool based on:
1. **Scoverage indicators:**
   - `scoverage-maven-plugin` in pom.xml
   - `sbt-scoverage` plugin in build.sbt
   - Scala source directories (`src/main/scala`, `src/test/scala`)
   - Scoverage report files exist

2. **JaCoCo indicators:**
   - `jacoco-maven-plugin` in pom.xml
   - `jacoco` task in build.gradle
   - Java/Kotlin source directories
   - JaCoCo report files exist

### Default Report Locations

**Scoverage (Maven):**
- Multi-module aggregate: `target/cobertura.xml` (in parent)
- Per-module: `target/scoverage-report/cobertura.xml`
- Note: Use cobertura.xml, not scoverage.xml (native format)

**Scoverage (SBT):**
- `target/scala-<version>/scoverage-report/cobertura.xml`

**JaCoCo (Maven):**
- `target/site/jacoco/index.html`

**JaCoCo (Gradle):**
- `build/reports/jacoco/test/html/index.html`
- Multi-module: `build/jacocoHtml/index.html`

## Implementation Plan

1. **Extract common code into coverage_common.py:**
   - Baseline management (load/save functions)
   - Comparison logic (diff calculation, tolerance checking)
   - Common CLI args (--baseline, --save-baseline, --set-baseline, --tolerance)
   - Percentage calculation utilities
   - Exit code handling

2. **Refactor jacoco-compare.py:**
   - Keep JaCoCo HTML parsing
   - Import common functions from coverage_common
   - Reduce from ~215 lines to ~50-70 lines

3. **Create scoverage-compare.py:**
   - Implement Cobertura XML parsing
   - Import common functions from coverage_common
   - Support same CLI interface as jacoco-compare.py
   - ~50-70 lines

4. **Update SKILL.md:**
   - Document Scoverage support properly
   - Add report path detection for Scoverage
   - Update examples to show Scala/Scoverage usage
   - Fix misleading claims about JaCoCo supporting Scala

5. **Add tests:**
   - Unit tests for coverage_common.py
   - Unit tests for each parser (with mock HTML/XML)
   - Integration tests using a real Scala project with Scoverage

## Benefits

- **Code reuse:** ~150 lines of shared code
- **Consistency:** Same CLI and behavior across tools
- **Maintainability:** Common logic in one place
- **Extensibility:** Easy to add new tools (Clover, Cobertura, etc.)
- **Testability:** Each component can be tested independently

## Future Extensions

- **Cobertura native support** (Java projects using Cobertura instead of JaCoCo)
- **Clover support** (Atlassian projects)
- **Kover support** (Kotlin multiplatform)
- **Unified coverage-compare.py** (auto-detects tool and delegates to appropriate parser)
