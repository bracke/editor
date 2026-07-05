# Real Ada Corpus Validation — Case 1430

Case 1430 implements project-scale item 3: real Ada corpus validation.

The finite RM remediation backlog remains closed.  This pass adds a validation model for source-shaped Ada 2022 corpus rows and checks that the semantic model can distinguish:

- legal Ada 2022 units that must be accepted,
- illegal Ada 2022 units that must be rejected,
- legal constructs that preserve runtime checks,
- warning-only constructs that must not become hard errors,
- cross-unit/project-index cases whose semantic consumers must agree,
- false positives,
- false negatives,
- missing diagnostic spans,
- duplicate diagnostic floods,
- stale corpus evidence, and
- consumer disagreement.

The validation gate is intentionally evidence-driven.  It does not create new `Remaining_*` work.  Future semantic work must come from an actual corpus failure, a source-shaped reproducer, or a specific RM contradiction.
