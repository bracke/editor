Pass1288 - Remaining RM edge recheck application legality

This pass adds Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality.

The package consumes Pass1287 remaining RM edge recheck eligibility rows and applies
that eligibility back into the remaining-edge diagnostic/closure boundary. Current
non-diagnostic evidence stays current, eligible rows may be exposed as current
accepted semantic evidence, and unresolved prerequisite rows remain withheld with
blocker-family identity preserved.

Preserved blocker families include remaining RM edge blockers, stabilized closure
blockers, source fingerprint mismatches, substitution fingerprint mismatches,
multiple prerequisites, explicit recheck-required gates, and indeterminate rows.

Added AUnit coverage in
Test_Ada_Remaining_RM_Edge_Recheck_Application_Legality_Pass1288.
