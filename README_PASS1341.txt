Pass1341 - Partial Evidence Precision Audit

This pass starts integration/audit phase 7 for Editor Phase 579.

Added package:

  Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341

Purpose:

  Harden the completed Ada semantic vertical slices and post-slice audit layers
  against false positives and false negatives when semantic evidence is partial,
  stale, blocked, or intentionally indeterminate.

The pass classifies source-shaped semantic rows as one of:

  * Legal
  * Illegal
  * Legal with runtime check
  * Indeterminate / blocked because required evidence is incomplete
  * Partial coverage
  * Missing checker

The audit rejects:

  * hard Ada legality diagnostics emitted from incomplete evidence
  * legal-with-runtime-check cases collapsed into hard illegal diagnostics
  * indeterminate rows silently treated as legal or illegal
  * stale evidence used as authoritative
  * partial coverage treated as complete
  * missing checker states treated as complete
  * complete-evidence violations that are not diagnosed
  * legal cases that receive hard diagnostics
  * diagnostics without semantic blocker-family identity
  * consumers that hide blocker, partial, or missing-checker states
  * source/AST/type/profile/substitution/effect/consumer fingerprint mismatch

Covered evidence areas:

  * source and AST evidence
  * type and profile evidence
  * view and cross-unit evidence
  * flow and effect evidence
  * representation and freezing evidence
  * consumer precision
  * aggregate/assignment/predicate interactions
  * generic/overload/profile interactions
  * tasking/parallel/shared-state interactions

Added AUnit tests:

  Test_Ada_Partial_Evidence_Precision_Audit_Pass1341

The tests verify preserved legal/illegal/runtime-check/indeterminate/partial/missing
states, hard-diagnostic rejection under incomplete evidence, runtime-check
preservation, indeterminate precision, partial/missing coverage barriers, complete
violation detection, stale-evidence rejection, fingerprint freshness, blocker
surfacing, and blocker-family requirements.

Registered the test case in Core_Suite.
