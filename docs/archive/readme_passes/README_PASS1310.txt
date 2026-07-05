Pass1310 implements Editor.Ada_Exception_Finalization_Vertical_Slice_Legality.

This is a vertical Ada semantic slice, not a diagnostic/provenance/recheck wrapper.
It models concrete exception propagation and finalization legality over source-shaped rows.

Added source package:
  src/core/editor-ada_exception_finalization_vertical_slice_legality.ads
  src/core/editor-ada_exception_finalization_vertical_slice_legality.adb

Added AUnit test package:
  tests/src/test_ada_exception_finalization_vertical_slice_legality_pass1310.ads
  tests/src/test_ada_exception_finalization_vertical_slice_legality_pass1310.adb

Registered in:
  tests/src/core_suite.adb

Semantic coverage added:
  - raise statement and raise expression exception visibility/kind checks
  - exception handler choice presence, duplicate choice, and reachability checks
  - reraise outside handler rejection
  - required local handler versus propagation checks
  - controlled object finalization procedure and ordering checks
  - Adjust/Finalize profile compatibility checks
  - limited controlled finalization blockers
  - abort and abortable-select finalization safety checks
  - task termination finalization blockers
  - accessibility, renaming, shared-state, representation, predicate, and elaboration blockers
  - source, AST, effect, and substitution fingerprint freshness
  - multiple-blocker and indeterminate preservation

The tests use source-shaped exception, handler, controlled object, abort, task termination, renaming, and stale-evidence scenarios rather than synthetic closure-state transitions.
