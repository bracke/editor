Pass1437: legacy code removal

This pass performs the first destructive legacy-code removal after the Phase 579 project-scale closure.

Removed legacy code:
- src/core/editor-ada_repair_gated_diagnostic_provenance.ads
- src/core/editor-ada_repair_gated_diagnostic_provenance.adb
- tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.ads
- tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.adb

Core_Suite was updated to remove Test_Ada_Repair_Gated_Diagnostic_Provenance_Pass1151 and to register Test_Ada_Phase579_Legacy_Code_Removal_Pass1437.

The removed scaffold was an old repair-gated diagnostic provenance layer superseded by the frozen Remaining_* closure in pass1428, the architecture cleanup gate in pass1429, and the project-scale closure in pass1436.
