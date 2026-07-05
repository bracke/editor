Pass1364 implements RM Gap Burn-Down Pass 22.

Added package:

  Editor.Ada_RM_Gap_Burn_Down_Pass1364

Purpose:

  Burns down the diagnostic, blocker-family, and source-span precision gap after
  project-scale semantic index ownership.  The pass requires consumer-visible
  Ada semantic evidence to be normalized into stable blocker families, precise
  source spans, deterministic diagnostic ordering, and consistent legality
  states.  It prevents diagnostics, hover/detail payloads, semantic colouring,
  outline/navigation, and the build-diagnostic bridge from reclassifying or
  duplicating canonical semantic results.

Covered semantics:

  * stable blocker-family normalization
  * rejection of duplicate blocker spellings
  * rejection of generic fallback blockers when a precise RM-family blocker is
    available
  * preservation of legal, illegal, legal-with-runtime-check, warning-only,
    indeterminate, partial, and missing-checker classifications
  * smallest meaningful source-span enforcement
  * association/selector/actual/attribute/operator span precision
  * local reference and target-unit evidence for cross-unit diagnostics
  * recovered/partial syntax span degradation
  * deterministic diagnostic deduplication and ordering
  * primary versus secondary evidence ordering
  * consumer-visible consistency across diagnostics, semantic colouring,
    outline/navigation, hover/details, and build bridge paths
  * incremental diagnostic stability across unchanged errors and span movement
  * stale diagnostic and stale consumer-state rejection
  * source/AST/type/profile/project-index/closure/consumer/request fingerprint
    freshness

Added tests:

  Test_Ada_RM_Gap_Burn_Down_Pass1364

The test suite covers balanced legal, illegal, runtime-check, warning-only,
indeterminate, deduplication/ordering, and incremental-stability rows, plus
negative cases for duplicate diagnostics, duplicate blocker spellings, generic
fallback blockers, missing precise blockers, hard diagnostics from incomplete
or runtime-check evidence, imprecise source spans, cross-unit span loss,
recovered syntax pretending to be complete, nondeterministic ordering,
consumer reclassification, build diagnostic conflation, stale diagnostics,
stale consumer state, stale fingerprints, and unconsumed semantic results.

Registered in:

  tests/src/core_suite.adb
