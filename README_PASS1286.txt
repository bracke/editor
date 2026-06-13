Pass1286: Remaining RM Edge Remediation Worklist Legality

Implemented Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality.

This pass consumes Pass1285 remaining RM edge stabilized diagnostics and converts blocker rows into deterministic prerequisite work items. Accepted rows remain current semantic evidence. Blocking rows preserve their original remaining-edge, stabilized-closure, fingerprint, multiple-blocker, recheck-required, and indeterminate families before later recheck/stabilization passes may trust them.

Added AUnit coverage in Test_Ada_Remaining_RM_Edge_Remediation_Worklist_Legality_Pass1286 and registered it in core_suite.adb.
