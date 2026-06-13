Pass1291 - Remaining RM edge stabilized closure

Implemented Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality.

This pass consumes Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality rows from Pass1290 and turns stable remaining Ada RM edge evidence into first-class semantic closure rows.

Semantic behaviour:
- stable promoted-current rows become accepted current closure evidence;
- stable promoted-not-required rows become accepted non-diagnostic closure evidence;
- stable remaining-edge blockers become explicit closure blockers;
- stable stabilized-closure blockers remain explicit closure blockers;
- source/substitution fingerprint blockers remain explicit closure blockers;
- multiple-prerequisite blockers are preserved;
- indeterminate rows remain degraded;
- changed or recheck-required rows are not admitted as trusted closure evidence.

Added AUnit regression coverage in Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Legality_Pass1291.
