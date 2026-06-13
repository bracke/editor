Pass1290: Remaining RM edge stabilization gate

This pass adds Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality.

It consumes Pass1289 remaining RM edge convergence rows and turns them into a bounded stabilization gate. Stable current and stable not-required rows are promoted as semantic evidence. Stable withheld rows remain withheld with their original blocker family: remaining-edge blockers, stabilized-closure blockers, source fingerprint mismatches, substitution fingerprint mismatches, multiple prerequisites, recheck-required gates, and indeterminate states. Changed convergence rows are not promoted and instead request another bounded recheck.

Added AUnit coverage in Test_Ada_Remaining_RM_Edge_Stabilization_Gate_Legality_Pass1290 and registered it in core_suite.adb.
