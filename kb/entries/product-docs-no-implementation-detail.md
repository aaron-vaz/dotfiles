---
name: "product-docs-no-implementation-detail"
description: "Material written for product managers leaves out implementation/infrastructure detail (storage services like S3, queues, Lambda, push providers, DB rows, SQL, class names). Keep behaviour, values, limits and what it takes to change them."
type: feedback
tags: [product, documentation, presentations, audience, writing]
status: active
---

Decks, docs and write-ups for a product audience describe behaviour, rules, values and limits in plain
language. They do not mention how it is implemented: storage services (S3), queues (SQS), serverless
functions (Lambda), push providers' internals (FCM tokens, batches), databases/rows/SQL, class or file names.

**Why:** User instruction (2026-09-29), on a product walkthrough deck: "We can remove the technical
details like s3 product don't care about that". Product needs to understand and tweak behaviour; the
mechanism is noise to them.

**How to apply:**
- Slide/page body: behaviour and numbers only. "Evidence photos are stored but nobody can view them", not
  "stored in S3 under report-evidence/".
- Keep what product can act on: current value, limit, what changing it does, and the change type
  (setting / feature switch / copy / seed data / engineering work).
- Engineer pointers (file:line, config keys) go in at most one short "For engineers" line in speaker notes,
  or a separate engineering appendix — never in the body.
- Material that will be SENT to product is addressed to them: never refer to "product" in the third
  person ("this is for product", "product can change", "a product person would", "For product",
  "product decision", "product hasn't supplied"). Say "you" / "the team", or just state the fact
  ("The final list of reasons hasn't been decided"). User (2026-09-29): "The slides are to send to
  product we can't have stuff like 'this is for product' reads weirdly".
- Vendor names that are product-relevant choices (e.g. a maps provider as the venue source) may stay;
  plumbing vendors (S3, SQS, Lambda, Secrets Manager) go.

## Related

- [[delegate-simple-work-to-sonnet-subagents]]
