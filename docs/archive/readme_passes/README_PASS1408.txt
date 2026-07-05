Pass1408 - Remaining class-wide membership dispatching edge remediation

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1408.

This pass remediates Remaining_Class_Wide_Membership_Dispatching_Edge, a concrete remaining semantic edge where class-wide membership legality, tagged root compatibility, interface membership compatibility, controlling operand classification, dispatching candidate-set agreement, class-wide conversion compatibility, abstract primitive availability, runtime tag-check preservation, and semantic consumer surfacing share one canonical result.

The new model rejects the illegal source-shaped cases, preserves runtime-check and warning-only results,
surfaces private/full-view and missing-evidence blockers as indeterminate, rejects stale semantic evidence,
and requires Pass1366 inventory ownership, covered remediation state, regression corpus balance, semantic
consumer agreement, and fresh source/AST/type/evidence/effect/consumer fingerprints.

Added Test_Ada_RM_Remaining_Gap_Remediation_Pass1408 and registered it in Core_Suite. The tests cover legal, illegal, runtime-check,
warning-only, indeterminate, inventory-gate, consumer-gate, and fingerprint scenarios.
