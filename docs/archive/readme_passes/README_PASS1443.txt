Pass1443 - Core_Suite pruning

Implemented project-scale cleanup item 4: Core_Suite pruning.

Added Editor.Ada_Core_Suite_Pruning_Pass1443 and matching AUnit coverage.  The pass records which tests remain active in Core_Suite, which legacy-scaffold tests are pruned from the active suite, which removed legacy test-file families are expected to be absent, and which historical evidence may remain off-suite only.

Core_Suite changes:
- Removed active registration for Test_Ada_Repair_Gated_Diagnostic_Integration_Pass1150.
- Removed active registration for Test_Ada_Final_Semantic_Remediation_Worklist_Legality_Pass1204.
- Removed active registration for Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index_Pass1294.
- Added active registration for Test_Ada_Core_Suite_Pruning_Pass1443.

The pass rejects stale legacy registrations, missing canonical registrations, removed test files that still remain active, reopened Remaining_* gaps after pass1428, command alias/compatibility leaks, and stale suite/test/inventory fingerprints.
