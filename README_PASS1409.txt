Pass1409 - Remaining access parameter allocator master edge remediation

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1409.

This pass remediates Remaining_Access_Parameter_Allocator_Master_Edge, a concrete remaining semantic edge where access parameters initialized from allocator-created objects, master/lifetime evidence, storage-pool evidence, null-exclusion legality, static accessibility escape rejection, unchecked-deallocation hazard rejection, controlled allocation/finalization hazard rejection, runtime accessibility-check preservation, and semantic consumer surfacing share one canonical result.

The new model rejects the illegal source-shaped cases, preserves runtime-check and warning-only results,
surfaces private/full-view and missing-evidence blockers as indeterminate, rejects stale semantic evidence,
and requires Pass1366 inventory ownership, covered remediation state, regression corpus balance, semantic
consumer agreement, and fresh source/AST/type/evidence/effect/consumer fingerprints.

Added Test_Ada_RM_Remaining_Gap_Remediation_Pass1409 and registered it in Core_Suite. The tests cover legal, illegal, runtime-check,
warning-only, indeterminate, inventory-gate, consumer-gate, and fingerprint scenarios.
