# Real-World Case Studies - jvm-test-quality Skill

This document captures real-world results from using the jvm-test-quality skill across different projects. These examples demonstrate the skill's effectiveness and provide patterns for similar improvements.

---

## Case Study 1: common-api-gateway (Spring WebFlux / Java)

**Repository**: [eg-internal/common-api-gateway](https://github.com/eg-internal/common-api-gateway)
**Timeline**: Phase 1-5 over 3 weeks
**Service Tier**: Tier 2 (80% line, 70% branch target)

### Initial State
- **Coverage**: 58% instructions, 45% branches
- **Challenge**: Low coverage with mix of unit and integration tests
- **Key insight**: In this project's initial setup, JaCoCo only instrumented unit test runs; integration tests ran without coverage aggregation (later addressed separately)

### Improvement Journey

| Phase | PRs | Coverage Gain | Key Actions |
|-------|-----|---------------|-------------|
| Phase 1-2 | [#874](https://github.com/eg-internal/common-api-gateway/pull/874) | 58% → 65% instructions | Behavioral verification, parametrized tests |
| Phase 3-5 | [#875](https://github.com/eg-internal/common-api-gateway/pull/875) | 65% → 74% instructions | Strategic targeting, helper methods |

### Final Results
- **Line Coverage**: 58% → 74.81% (+16.81 percentage points)
- **Branch Coverage**: 45% → 61.71% (+16.71 percentage points)
- **Tests Added**: 500+ lines of tests across 6 new test files
- **Key Discovery**: 61 integration tests covering "0% unit coverage" classes
- **Outcome**: Accepted 74.81% + comprehensive integration tests as well-tested

### Techniques Applied
✅ **Behavioral Verification** - Tests verify outcomes, not just execution
✅ **Strategic Targeting** - Prioritized branches > error paths > edge cases
✅ **Parametrized Tests** - Reduced duplication for similar test cases
✅ **Helper Methods** - Extracted repeated assertion patterns
✅ **Integration Test Recognition** - Understood JaCoCo setup limitations; integration coverage addressed separately

### PR Highlights

**PR #874 Summary**:
- Added behavioral verification to existing tests
- Created parametrized tests for input validation
- Focused on high-impact, low-effort wins
- Coverage: 58% → 65% instructions

**PR #875 Summary**:
- Strategic targeting of uncovered branches
- Helper methods for repeated assertions
- Type-safe assertions with AssertJ
- Final coverage: 74.81% instructions, 61.71% branches

### Key Learnings
1. **JaCoCo ≠ Total Coverage**: Without additional configuration, integration tests running in a separate JVM don't appear in JaCoCo reports (integration test coverage was later implemented in a separate effort)
2. **Quality > Quantity**: 74% with behavioral verification > 90% with execution-only tests
3. **Strategic Wins**: Targeting branches yields highest ROI
4. **When to Stop**: ~75% + integration tests = well-tested codebase

---

## Case Study 2: mls-txef (Scala / Maven)

**Repository**: [eg-internal/mls-txef](https://github.com/eg-internal/mls-txef)
**Timeline**: Single PR
**Service Tier**: Tier 2 (80% line, 70% branch target)
**Coverage Tool**: Scoverage 1.4.11

### Initial State
- **Coverage**: 93.51% line (already high)
- **Stack**: Java 11, Scala 2.13.9, Maven
- **Challenge**: Already meeting tier goals; fine-tuning high-value gaps

### Improvement Journey

**PR [#974](https://github.com/eg-internal/mls-txef/pull/974)** - Test coverage improvements

### Results
- **Line Coverage**: 93.51% → 94.91% (+1.40 percentage points)
- **Tests Added**: 248 lines across multiple test files
- **Approach**: Targeted gaps in already well-tested codebase
- **Status**: Service owner approved

### Techniques Applied
✅ **Scoverage Support** - First real-world validation of Scala coverage tracking
✅ **Fine-tuning High Coverage** - Improving already-strong test suites
✅ **Scala Test Patterns** - ScalaTest, Mockito Scala integration

### Key Learnings
1. **Scoverage XML Format**: Must use `cobertura.xml` (not `scoverage.xml`)
2. **High Coverage Tuning**: Skill works for both low and high coverage scenarios
3. **Scala Compatibility**: Behavioral verification patterns apply to Scala

---

## Case Study 3: mls-txef-publisher (Scala / Maven)

**Repository**: [eg-internal/mls-txef-publisher](https://github.com/eg-internal/mls-txef-publisher)
**Timeline**: Single PR
**Service Tier**: Tier 2 (80% line, 70% branch target)
**Coverage Tool**: Scoverage 1.4.11

### Initial State
- **Overall Coverage**: 84% line, 80% branch (already meets tier goals)
- **Challenge**: Per-class analysis revealed significant gaps
- **Stack**: Java 17, Scala 2.13.2, Maven

### Per-Class Analysis (Before)

| Class | Line % | Branch % | Lines | Priority |
|-------|--------|----------|-------|----------|
| `ProductTaxRuleStreamRepository` | 33% | 17% | 210 | **High** |
| `PropertyWhitelistDataPublisher` | 38% | 100% | 78 | **High** |
| `VrBaseRepository` | 69% | 67% | 130 | **High** |
| `VrboLodgingTaxRulesRepository` | 70% | 70% | 154 | High |
| `VrboUnitLodgingTaxRepository` | 70% | 70% | 152 | High |
| `HotelServiceFeeDataRepository` | 94% | **50%** | — | Branch outlier |
| `TpidServiceFeeDataRepository` | 95% | **50%** | — | Branch outlier |

### Improvement Journey

**PR [#346](https://github.com/eg-internal/mls-txef-publisher/pull/346)** - Improve unit test coverage

### Results
- **Overall Coverage**: 84% → 86% line (+2 pp), 80% → 82% branch (+2 pp)
- **Tests Added**: 24 new tests across 7 files (222 tests total, 0 failures)
- **Approach**: Skill-driven prioritization and implementation

### Per-Class Results (After)

| Class | Line (before → after) | Branch (before → after) | Tests Added |
|-------|----------------------|------------------------|-------------|
| **PropertyWhitelistDataPublisher** | 38% → **100%** | 100% → 100% | 3 tests (Hollow writeToDataStore) |
| **VrBaseRepository** | 69% → **94%** | 67% → **100%** | 9 tests (new file) |
| **VrboLodgingTaxRulesRepository** | 70% → **75%** | 70% → 70% | 2 tests (exception handling) |
| **VrboUnitLodgingTaxRepository** | 70% → **75%** | 70% → 70% | 2 tests (exception handling) |
| **ProductTaxRuleStreamRepository** | 33% → **45%** | 17% → **33%** | 5 tests (offset scenarios) |

### Techniques Applied
✅ **Tier-Based Prioritization** - Identified gaps despite meeting overall goals
✅ **Impact-Effort Analysis** - Prioritized high-impact, achievable targets
✅ **Abstract Class Testing** - Created tests for `VrBaseRepository` base class
✅ **Hollow Framework** - Used `doAnswer` for Hollow `writeToDataStore` mocking
✅ **Exception Path Coverage** - Added `SerializationException`, `KafkaException` tests

### Files Modified

**New:**
- `VrBaseRepositorySpec.scala` - 9 tests for abstract base class

**Enhanced:**
- `ProductTaxStreamRepositorySpec.scala` - 5 new tests (offset scenarios, snapshot cycles)
- `PropertyWhitelistDataPublisherSpec.scala` - 3 new tests (Hollow populator)
- `PlatformRepositorySpec.scala` - 2 new tests (exception handling)
- `VrboLodgingTaxRulesRepositorySpec.scala` - 2 new tests (exception handling)
- `HotelServiceFeeDataRepositorySpec.scala` - 2 new tests (parameter variations)
- `TpidServiceFeeDataRepositorySpec.scala` - 3 new tests (edge cases)

### Key Learnings
1. **Overall Coverage ≠ Quality**: Project met tier goals but had significant per-class gaps
2. **Skill-Driven Prioritization**: Automated analysis identified 7 high-priority targets
3. **Abstract Class Value**: Testing base classes improves coverage across implementations
4. **Dead Code Detection**: Some untested branches were unreachable (e.g., `if (result.isEmpty)` after `Await.ready`)

### PR Description Highlights
- Skill analyzed Scoverage report and identified project as Tier 2
- Per-class analysis found gaps despite overall compliance
- Skill recommended improvement order; implementer chose top 5
- Results validated skill's prioritization algorithm

---

## Validation Summary

| Project | Language | Build | Coverage Tool | Coverage Gain | PR Count | Timeline |
|---------|----------|-------|---------------|---------------|----------|----------|
| **common-api-gateway** | Java | Maven | JaCoCo | 58% → 74% (+16pp) | 2 | 3 weeks |
| **mls-txef** | Scala | Maven | Scoverage | 93% → 94% (+1pp) | 1 | 1 session |
| **mls-txef-publisher** | Scala | Maven | Scoverage | 84% → 86% (+2pp) | 1 | 1 session |

**Total Impact**: 3 projects improved, 4 PRs merged, coverage tracking validated across Java and Scala

---

## Common Patterns Across Case Studies

### What Works
1. **Behavioral Verification** - Focus on outcomes, not execution
2. **Strategic Targeting** - Branches > error paths > edge cases
3. **Parametrized Tests** - Reduce duplication for similar scenarios
4. **Helper Methods** - Extract repeated assertion patterns
5. **Integration Test Recognition** - Understand coverage tool limitations
6. **Tier-Based Goals** - Appropriate targets based on service criticality

### What Doesn't Work
1. **Forcing Unit Tests** - Some code needs integration tests
2. **Chasing 100%** - Diminishing returns above ~75-85%
3. **Execution-Only Tests** - Tests without behavioral verification add noise
4. **Ignoring Per-Class Gaps** - Overall coverage masks significant holes

### Success Metrics
- ✅ Coverage increased in all cases
- ✅ Zero test failures introduced
- ✅ Behavioral verification validated
- ✅ Service owners approved all PRs
- ✅ Techniques applicable across languages (Java, Scala)
- ✅ Coverage tools validated (JaCoCo, Scoverage)

---

## Using These Examples

When applying the jvm-test-quality skill to a new project:

1. **Identify Similar Context**: Match your project to closest case study
   - Already high coverage (>85%)? See mls-txef
   - Moderate coverage (60-80%)? See mls-txef-publisher
   - Low coverage (<60%)? See common-api-gateway

2. **Apply Proven Techniques**: Use patterns from case studies
   - Behavioral verification (all projects)
   - Strategic targeting (common-api-gateway, mls-txef-publisher)
   - Parametrized tests (common-api-gateway)
   - Abstract class testing (mls-txef-publisher)

3. **Set Realistic Goals**: Use tier-based targets
   - Don't force 90% if Tier 2 (80%) is appropriate
   - Focus on quality over percentage

4. **Reference PRs**: Link to actual PRs for detailed implementation examples

---

**Maintained by**: Expedia Group
**Last Updated**: 2026-02-10
**Related**: See `SKILL.md` for skill documentation, `README.md` for quick start
