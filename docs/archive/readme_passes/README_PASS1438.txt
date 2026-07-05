Pass1438 — Legacy Code Removal 2

Selected cleanup: remove the obsolete diagnostic recovery render final status scaffold from the active source and test tree.

Removed from active tree:
- src/core/editor-ada_diagnostic_recovery_render_final_status.ads
- src/core/editor-ada_diagnostic_recovery_render_final_status.adb
- tests/src/test_ada_diagnostic_recovery_render_final_status_pass1098.ads
- tests/src/test_ada_diagnostic_recovery_render_final_status_pass1098.adb

Added:
- Editor.Ada_Legacy_Code_Removal_Pass1438
- Test_Ada_Legacy_Code_Removal_Pass1438
- docs/release/LEGACY_CODE_REMOVAL_PASS1438.md

Rationale:
The removed final-status leaf was historical diagnostic recovery/render scaffolding from the pre-closure phase. The canonical release state is now represented by the pass1428 remaining-gap closure, pass1429 architecture cleanup, pass1435 diagnostic quality validation, pass1436 project-scale closure, and pass1437 destructive cleanup gate. This pass keeps the remaining recovery render projection/lifecycle evidence as regression support while removing a superseded final status aggregation leaf from active ownership.

The pass rejects active source/test references to the removed package, lingering suite registrations, noncanonical replacement ownership, reopened Remaining_* gaps, and stale cleanup fingerprints.
