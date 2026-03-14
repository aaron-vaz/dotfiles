# Service Tier Coverage Guide

This guide helps you determine the appropriate coverage tier for your service and set realistic coverage goals based on Expedia Group's Application Tiering Standard.

> **Official Standard**: For the complete tiering methodology, evaluation criteria, and scoring formula, see the [Application Tiering Standard](https://backstage.expedia.biz/docs/open-standards/eg-arch-docs/Application-Tiering-Standard/) on Backstage.

## Coverage Goals by Tier

| Tier | Line Coverage | Branch Coverage | Complexity | Business Impact |
|------|---------------|-----------------|------------|-----------------|
| **Tier 0** | **90%** | **80%** | **75%** | Large-scale impact - foundational platforms |
| **Tier 1** | **85%** | **75%** | **70%** | Obstructs business operations |
| **Tier 2** | **80%** | **70%** | **65%** | Impairs business operations |
| **Tier 3** | **75%** | **65%** | **60%** | Minimal impact |
| **Tier 4** | **70%** | **60%** | **55%** | Non-production only |

---

## Understanding Expedia's Tier Definitions

Expedia Group determines service tiers based on **business criticality**, not just regulatory requirements. The official standard evaluates services across multiple criteria to calculate a criticality score.

### Key Evaluation Criteria

Services are evaluated based on:

1. **Interdependencies** (Most Important)
   - Impact on dependent systems
   - Number of critical systems affected
   - Cascading failure risk

2. **Customer Satisfaction**
   - Direct impact on traveler experience
   - Ability to shop and book
   - Frustration or inability to use services

3. **Reputational Impact**
   - Media coverage risk
   - Partner relationships
   - Brand damage potential

4. **Revenue Impact**
   - Direct revenue loss
   - Revenue generation capacity
   - Recovery time and cost

5. **Regulatory & Contractual Requirements**
   - Compliance obligations (PCI-DSS, SOX, GDPR)
   - Contractual SLAs
   - Data sensitivity (PCI data)

6. **Organizational Goals**
   - Service restoration capability
   - Productivity impact
   - Business continuity

> **Note**: The official standard uses a weighted scoring formula across these criteria. **Interdependencies** carry the highest weight because services with many critical dependencies have the broadest impact during incidents.

---

## Tier 0: Foundational Platforms (90% Coverage)

### Definition
**Large-scale impact**: Foundational platform components or EG systems that are critical dependencies to a large number of systems and would have a large area of impact during an incident.

### Key Characteristics
- **Many critical dependencies**: Large number (≥10) of Tier 1 systems depend on this service
- **Immediate impact**: Failure directly and immediately blocks dependent systems
- **High revenue risk**: Potential for significant revenue loss (>$500K per incident)
- **Regulatory obligations**: May include PCI-DSS, SOX, GDPR compliance requirements

### Coverage Requirements
- **Line Coverage**: 90%
- **Branch Coverage**: 80%
- **Complexity Coverage**: 75%
- **Method Coverage**: 90%

### Testing Strategy
- **Unit tests**: 90%+ coverage of all logic paths including edge cases
- **Integration tests**: End-to-end coverage of all critical workflows
- **Error path coverage**: Exhaustive testing of all failure scenarios
- **Security tests**: Penetration testing, vulnerability scanning, SAST/DAST
- **Compliance tests**: Automated validation of regulatory requirements
- **Chaos engineering**: Test system behavior under extreme conditions
- **Dependency testing**: Verify behavior when dependencies fail

### Why 90%?
- Failures impact many critical systems simultaneously
- High potential for cascading failures across the platform
- Significant revenue loss risk during incidents
- Regulatory fines and legal liability for compliance violations
- Recovery complexity is high
- Customer trust impact is severe

---

## Tier 1: Core Business Services (85% Coverage)

### Definition
**Could potentially become large-scale impact**: Core services that in case of an incident will obstruct the ability to conduct business.

### Key Characteristics
- **Direct business impact**: Prevents core business operations
- **Critical dependencies**: Several (< 10) Tier 1 systems depend on this service
- **Moderate revenue risk**: Documented revenue loss $20K-$500K per incident
- **Customer-facing**: Significant impact on traveler experience

### Coverage Requirements
- **Line Coverage**: 85%
- **Branch Coverage**: 75%
- **Complexity Coverage**: 70%
- **Method Coverage**: 85%

### Testing Strategy
- **Unit tests**: 85%+ coverage of all business logic
- **Integration tests**: Cover all critical business flows (payments, bookings, authentication)
- **Error path coverage**: Test common failure scenarios (timeouts, network errors, invalid inputs)
- **Security tests**: Regular penetration testing and vulnerability scanning
- **Performance tests**: Load testing for high-traffic scenarios
- **Rollback testing**: Verify clean rollback procedures

### Why 85%?
- Direct obstruction to business operations
- Financial loss from incidents can be substantial
- Customer experience severely degraded
- Security vulnerabilities have broad impact
- Rollback is complex and carries risk

---

## Tier 2: Business-Impacting Services (80% Coverage)

### Definition
**Can have an impact**: Services that in case of an incident impair the ability to conduct business.

### Key Characteristics
- **Business impairment**: Degrades but doesn't block business operations
- **Moderate dependencies**: Some dependent systems affected
- **Measurable revenue impact**: Revenue loss <$20K per incident
- **Customer impact**: Degraded experience but core functionality remains

### Coverage Requirements
- **Line Coverage**: 80%
- **Branch Coverage**: 70%
- **Complexity Coverage**: 65%
- **Method Coverage**: 80%

### Testing Strategy
- **Unit tests**: 80%+ coverage of business logic
- **Integration tests**: Cover main user workflows
- **Branch coverage**: Focus on conditional logic (if/else, switch)
- **Error handling**: Test common failure scenarios
- **Edge cases**: Boundary conditions, null handling
- **Happy path priority**: Ensure core functionality is well-tested

### Why 80%?
- Impairs but doesn't block business operations
- Moderate customer impact
- Business logic changes frequently
- Recovery is moderately complex
- Balance between quality and velocity

---

## Tier 3: Supporting Services (75% Coverage)

### Definition
**Impact should be minimal**: Services that in case of an incident have minimal to no impact on the ability to conduct business.

### Key Characteristics
- **Minimal business impact**: Little to no effect on core operations
- **Low dependencies**: Few or no critical systems depend on this service
- **Negligible revenue impact**: Revenue loss is minimal or none
- **Recoverable failures**: Failures are generally gracefully handled

### Coverage Requirements
- **Line Coverage**: 75%
- **Branch Coverage**: 65%
- **Complexity Coverage**: 60%
- **Method Coverage**: 75%

### Testing Strategy
- **Unit tests**: 75%+ coverage of core functionality
- **Integration tests**: Test key integration points
- **Happy path focus**: Prioritize main use cases
- **Critical path coverage**: Ensure no silent failures
- **Acceptance**: Some uncovered edge cases acceptable

### Why 75%?
- Minimal direct impact on business operations
- Failures are generally recoverable
- Rollback is relatively straightforward
- Balance between quality and velocity
- Cost/benefit trade-off for exhaustive testing

---

## Tier 4: Non-Production Services (70% Coverage)

### Definition
**No Impact**: Services in non-production environments with no impact on any other tier.

### Key Characteristics
- **Non-production only**: Development, testing, staging environments
- **No business impact**: Does not affect production operations
- **No dependencies**: Production systems do not depend on this service
- **Experimental**: May include proof-of-concepts, internal tools

### Coverage Requirements
- **Line Coverage**: 70%
- **Branch Coverage**: 60%
- **Complexity Coverage**: 55%
- **Method Coverage**: 70%

### Testing Strategy
- **Unit tests**: 70%+ coverage of core functionality
- **Happy path focus**: Prioritize main use cases
- **Basic integration tests**: Verify key workflows
- **Acceptance**: Edge cases and error paths may be lightly tested

### Why 70%?
- No production impact
- Development velocity prioritized
- Lower risk tolerance acceptable
- Cost/benefit strongly favors speed

---

## How to Determine Your Service Tier

### Quick Assessment Questions

1. **Interdependencies**
   - How many critical (Tier 1) systems depend on this service?
   - Would failure immediately block those systems?

2. **Customer Impact**
   - Can travelers shop and book if this service fails?
   - Is the experience degraded or completely blocked?

3. **Revenue Impact**
   - What's the documented or potential revenue loss from an incident?
   - How quickly can the service recover?

4. **Regulatory Requirements**
   - Does this service handle PCI-DSS, SOX, or GDPR regulated data?
   - Are there contractual SLA obligations?

5. **Reputational Risk**
   - Would failure result in negative media coverage?
   - Would partners be impacted?

> **Official Process**: Service tier assignments must be reviewed and approved by your domain architect through the established governance process. See the [Application Tiering Standard](https://backstage.expedia.biz/docs/open-standards/eg-arch-docs/Application-Tiering-Standard/) for the complete evaluation criteria and scoring methodology.

### Critical Application Dependency Rule

**Important**: Any service that has a **Critical Application Dependency** on a service in a particular tier will automatically adopt that tier.

> A **Critical Application Dependency** is a dependency that, in case of an incident, would block the ability of that system to provide its business function.

---

## Using Tiers with jvm-test-quality Skill

### Analyze Coverage

```bash
# Foundational platform (Tier 0)
/jvm-test-quality analyze --tier 0

# Core business service (Tier 1)
/jvm-test-quality analyze --tier 1

# Business-impacting service (Tier 2)
/jvm-test-quality analyze --tier 2

# Supporting service (Tier 3)
/jvm-test-quality analyze --tier 3

# Non-production service (Tier 4)
/jvm-test-quality analyze --tier 4
```

### Track Coverage Over Time

```bash
# Set baseline for Tier 0 service
/jvm-test-quality track --save-baseline --tier 0

# Set baseline for Tier 1 service
/jvm-test-quality track --save-baseline --tier 1

# Check against Tier 2 requirements
/jvm-test-quality track --tier 2

# Check against Tier 4 requirements
/jvm-test-quality track --tier 4
```

### CI/CD Integration

```yaml
# Tier 0 - Foundational platform requirements
- name: Coverage Gate (Tier 0)
  run: |
    mvn test jacoco:report
    python3 scripts/jacoco-compare.py --set-baseline 90.0 80.0 75.0 90.0 90.0
    python3 scripts/jacoco-compare.py || exit 1

# Tier 1 - Core business requirements
- name: Coverage Gate (Tier 1)
  run: |
    mvn test jacoco:report
    python3 scripts/jacoco-compare.py --set-baseline 85.0 75.0 70.0 85.0 85.0
    python3 scripts/jacoco-compare.py || exit 1

# Tier 2 - Business-impacting requirements
- name: Coverage Gate (Tier 2)
  run: |
    mvn test jacoco:report
    python3 scripts/jacoco-compare.py --set-baseline 80.0 70.0 65.0 80.0 80.0
    python3 scripts/jacoco-compare.py || exit 1

# Tier 3 - Supporting service requirements
- name: Coverage Gate (Tier 3)
  run: |
    mvn test jacoco:report
    python3 scripts/jacoco-compare.py --set-baseline 75.0 65.0 60.0 75.0 75.0
    python3 scripts/jacoco-compare.py || exit 1

# Tier 4 - Non-production requirements
- name: Coverage Gate (Tier 4)
  run: |
    mvn test jacoco:report
    python3 scripts/jacoco-compare.py --set-baseline 70.0 60.0 55.0 70.0 70.0
    python3 scripts/jacoco-compare.py || exit 1
```

---

## Special Cases

### Microservices Architecture

Each microservice should be evaluated independently based on its business criticality:

```
platform-auth-service     → Tier 0 (many critical dependencies, foundational)
payment-gateway-service   → Tier 0 (PCI-DSS, high dependency count, high revenue risk)
booking-service           → Tier 1 (core business, obstructs operations)
search-service            → Tier 1 (core business, high revenue impact)
user-profile-service      → Tier 2 (impairs experience, moderate impact)
notification-service      → Tier 3 (minimal business impact)
analytics-collector       → Tier 3 (minimal business impact)
dev-tools-api            → Tier 4 (non-production tooling)
```

### Monolithic Applications

Evaluate by module/package based on business impact:

```
com.expediagroup.platform.*     → Tier 0 (foundational, many dependencies)
com.expediagroup.payment.*      → Tier 0 or Tier 1 (PCI-DSS, revenue critical)
com.expediagroup.booking.*      → Tier 1 (core business)
com.expediagroup.search.*       → Tier 1 (core business)
com.expediagroup.profile.*      → Tier 2 (supporting business)
com.expediagroup.notification.* → Tier 3 (minimal impact)
com.expediagroup.internal.*     → Tier 4 (internal tooling)
com.expediagroup.util.*         → Tier 4 (utilities)
```

### Legacy Code

Start with achievable targets and incrementally improve:

```
Year 1: Achieve 70% (Tier 4) baseline coverage
Year 2: Achieve 80% (Tier 2) for business-critical modules
Year 3: Achieve 85% (Tier 1) for core business modules
Year 4: Achieve 90% (Tier 0) for foundational platform modules
```

---

## Exceptions and Trade-offs

### When to Deviate from Tier Goals

**Below Tier Goal:**
- Legacy code with comprehensive integration tests
- Infrastructure glue code (Spring configurations, DTOs)
- Generated code (Protobuf, JAXB, Lombok)
- Acceptable: 75% unit coverage + strong integration tests > 85% unit coverage alone

**Above Tier Goal:**
- Critical algorithms (encryption, complex calculations)
- Edge case-heavy logic (date/time handling, parsers)
- State machines with many transitions
- Acceptable: Aim for 100% when complexity warrants it

### Remember

> **Coverage is a means, not an end.**
>
> - 90% coverage with poor tests < 75% coverage with behavioral verification
> - Integration tests > unit tests for infrastructure code
> - Strategic 80% > shotgun 90%
> - Focus on **business impact** and **dependencies**, not just percentages

---

## Tiering Governance

- **Tier assignments** must be approved by your domain architect
- **Annual reassessment** is required per the governance process
- **Changes to tier** require domain architect approval
- **Tracking**: Maintained through Business Continuity Management (BCM) governance process

For questions about your service's tier assignment, consult with your domain architect or refer to the [Application Tiering Standard](https://backstage.expedia.biz/docs/open-standards/eg-arch-docs/Application-Tiering-Standard/).

---

## Quick Reference

| Tier | Line % | Branch % | Business Impact | Key Factor |
|------|--------|----------|----------------|------------|
| **0** | 90% | 80% | Large-scale impact | Foundational platform, many critical dependencies |
| **1** | 85% | 75% | Obstructs business | Core business service, prevents operations |
| **2** | 80% | 70% | Impairs business | Business-impacting, degrades operations |
| **3** | 75% | 65% | Minimal impact | Supporting service, minimal business impact |
| **4** | 70% | 60% | No impact | Non-production only |

---

**Version**: 2.0.0
**Last Updated**: 2026-02-04
**Based on**: [Expedia Group Application Tiering Standard v1.00](https://backstage.expedia.biz/docs/open-standards/eg-arch-docs/Application-Tiering-Standard/) (Approved 29 Jul 2024)
