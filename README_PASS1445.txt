Pass1445: Phase 579 final dead-code sweep

Added: Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445
AUnit: Test_Ada_Phase579_Final_Dead_Code_Sweep_Pass1445
Release doc: docs/release/FINAL_DEAD_CODE_SWEEP_PASS1445.md

This pass completes project-scale cleanup item 6: final dead-code sweep.

Removed orphaned off-suite legacy tests:
- tests/src/test_ada_repair_gated_diagnostic_integration_pass1150.ads
- tests/src/test_ada_repair_gated_diagnostic_integration_pass1150.adb
- tests/src/test_ada_final_semantic_remediation_worklist_legality_pass1204.ads
- tests/src/test_ada_final_semantic_remediation_worklist_legality_pass1204.adb
- tests/src/test_ada_remaining_rm_edge_stabilized_closure_search_index_pass1294.ads
- tests/src/test_ada_remaining_rm_edge_stabilized_closure_search_index_pass1294.adb

Retained regression dependencies:
- Editor.Ada_Final_Semantic_Remediation_Worklist_Legality remains retained because active final recheck/stabilization regression packages still depend on it.
- Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index remains retained because active coverage-proven RM edge regression packages still depend on it.

The pass rejects active references to removed surfaces, Core_Suite removal of still-registered tests, unowned legacy source, reopened Remaining_* gaps after pass1428, and stale cleanup fingerprints.
