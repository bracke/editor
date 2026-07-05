Editor Pass1110

Pass1110 adds Editor.Ada_Staticness_Range_Predicate_Legality.

Purpose:
  Add a widened compiler-grade semantic legality layer for Ada staticness
  requirements, static range membership, discrete/case choice legality,
  subtype predicate metadata, and linked outcomes from assignment, return,
  conversion/access/aggregate, and overload legality.

New package:
  src/core/editor-ada_staticness_range_predicate_legality.ads
  src/core/editor-ada_staticness_range_predicate_legality.adb

New regression:
  tests/src/test_ada_staticness_range_predicate_legality_pass1110.ads
  tests/src/test_ada_staticness_range_predicate_legality_pass1110.adb

Suite registration:
  tests/src/core_suite.adb registers Test_Ada_Staticness_Range_Predicate_Legality_Pass1110.

Semantic coverage added:
  - static range-compatible values
  - static discrete/case choice-compatible values
  - static constraint-compatible values
  - required-static-expression failures
  - non-static static-required expressions
  - unresolved static names
  - malformed static expressions
  - static division by zero
  - static binding cycles
  - unsupported static attributes
  - range violations and null ranges
  - choice out-of-range diagnostics
  - duplicate static choices
  - choice coverage gaps
  - static predicate success/failure
  - dynamic predicate preservation metadata
  - unresolved predicates
  - non-static predicates where staticness is required
  - linked assignment/return/conversion/access/aggregate/overload compatibility
  - linked semantic errors
  - unresolved universal numeric cases
  - deterministic counters, lookups, and fingerprints

Invariant notes:
  The package is snapshot-owned and projection-free. It performs no parsing,
  rendering-side analysis, file save/reload, dirty-state mutation, command or
  keybinding registration/mutation, workspace/session mutation, render mutation,
  compiler invocation, LSP integration, external parser generation, Python
  integration, or shell-script integration.
