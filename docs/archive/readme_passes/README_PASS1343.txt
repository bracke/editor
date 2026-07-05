Pass1343 - RM Gap Burn-Down Pass 1

This pass starts the post-audit burn-down phase.  It deliberately does not add another coverage, provenance, search, or diagnostic wrapper.  Instead it closes a concrete partial RM-family gap identified by the integration/audit sequence: aggregate values used as assignment, conversion, qualified-expression, component-update, or generic-actual sources must be checked through one coherent legality result.

Added package:

  Editor.Ada_RM_Gap_Burn_Down_Pass1343

The package burns down the aggregate/assignment/predicate interaction gap by combining evidence that had previously lived in separate slices:

  * aggregate association completeness
  * duplicate, extra, and mixed named/positional associations
  * static choice requirements and overlap checks
  * component type compatibility
  * discriminant compatibility
  * defaulted component availability
  * variant component activity
  * assignment target variable-view legality
  * static accessibility escapes
  * runtime accessibility checks
  * static range violations
  * runtime range checks
  * static predicate violations
  * runtime predicate checks
  * private view, limited view, and missing full-view blockers
  * remediation entry presence
  * RM coverage matrix promotion to Covered
  * balanced regression evidence
  * semantic consumer surfacing
  * source/AST/type/profile/substitution/effect/consumer fingerprint freshness

The burn-down model classifies each source-shaped row as Legal, Illegal, Legal_With_Runtime_Check, or Indeterminate.  A row is considered burned down only when the new legality rule is present, the remediation/coverage entries are present, the coverage entry is promoted to Covered, balanced regression evidence exists, the semantic result is consumed, a real semantic consumer is reached, and all required fingerprints are fresh.

Added AUnit suite:

  Test_Ada_RM_Gap_Burn_Down_Pass1343

Coverage includes:

  * balanced closure of the aggregate/assignment/predicate gap
  * missing, duplicate, extra, mixed, nonstatic, overlapping, type-mismatched, discriminant-mismatched, missing-defaulted, and inactive-variant aggregate cases
  * static accessibility, range, and predicate violations as hard illegal results
  * accessibility/range/predicate runtime-check preservation
  * private, limited, and missing-full-view indeterminate blockers
  * required remediation, matrix, package, new-rule, corpus, consumer, and consumption evidence
  * stale fingerprint and unexpected-classification rejection

Registered the new test in Core_Suite.
