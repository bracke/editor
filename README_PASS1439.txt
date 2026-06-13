Pass1439 - Legacy code removal: diagnostic recovery render final projection/lifecycle bundle

This pass performs the third post-closure destructive legacy cleanup for Phase 579.
It removes the obsolete diagnostic recovery render final projection and lifecycle
scaffolds from the active source and test tree.  Those pass1096/pass1097 surfaces
were historical recovery/projection evidence from the pre-closure diagnostic loop
and are now superseded by the project-scale closure, diagnostic-quality validation,
and legacy cleanup gates.

Removed from active source tree:

* src/core/editor-ada_diagnostic_recovery_render_final_projection.ads
* src/core/editor-ada_diagnostic_recovery_render_final_projection.adb
* src/core/editor-ada_diagnostic_recovery_render_final_lifecycle.ads
* src/core/editor-ada_diagnostic_recovery_render_final_lifecycle.adb

Removed from active test tree:

* tests/src/test_ada_diagnostic_recovery_render_final_projection_pass1096.ads
* tests/src/test_ada_diagnostic_recovery_render_final_projection_pass1096.adb
* tests/src/test_ada_diagnostic_recovery_render_final_lifecycle_pass1097.ads
* tests/src/test_ada_diagnostic_recovery_render_final_lifecycle_pass1097.adb

Added:

* Editor.Ada_Phase579_Legacy_Code_Removal_Pass1439
* Test_Ada_Phase579_Legacy_Code_Removal_Pass1439
* docs/release/LEGACY_CODE_REMOVAL_PASS1439.md

The replacement gate rejects active source/test references to the removed
scaffolds, stale removal evidence, noncanonical replacement owners, reopened
Remaining_* gaps after pass1428, and lingering Core_Suite references.
