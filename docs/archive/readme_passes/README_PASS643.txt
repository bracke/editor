Editor pass 643
=========================

Focus: Ada delta aggregate structural grammar coverage.

Changes:

* Added token-cursor production kinds for delta aggregate internals:
  - Production_Delta_Aggregate_Base
  - Production_Delta_Aggregate_Association
* Added top-level `with delta` detection so the base expression before the
  delta part is retained structurally without confusing it with extension
  aggregates.
* Wrapped each association after `with delta` in a delta-aggregate association
  production while reusing the existing component-association and choice-list
  parser path.
* Preserved the existing extension aggregate exclusion for `with delta`.
* Added AUnit coverage for simple, qualified-base, choice-list, and Ada 2022
  target-name delta aggregate forms, including recovery into a later object
  declaration.

This improves structural grammar coverage for Ada delta aggregate bases and
associations. It is not compiler-grade legality checking for component
selection, aggregate completeness, expected-type resolution, or target-name
legality.
