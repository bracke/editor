Pass1285 - Remaining RM edge stabilized diagnostic integration

This pass implements Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.

It consumes Pass1284 remaining RM edge stabilized closure-consumer rows and maps them into a diagnostic/feed-ready model. Accepted remaining-edge rows are withheld as current semantic evidence. Blocking rows are emitted while preserving blocker-family identity for remaining RM edge mismatches, stabilized closure blockers, missing stabilized closure evidence, source/substitution fingerprint mismatches, multiple blockers, recheck-required rows, and indeterminate rows.

The pass also extends Editor.Ada_Semantic_Diagnostic_Feed with Build_With_Remaining_RM_Edge_Stabilized_Diagnostics so stale remaining-edge diagnostic inputs reject the feed and current inputs emit only real blockers.

Added AUnit coverage in Test_Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration_Pass1285.
