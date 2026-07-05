Pass1396 - Remaining update expression target-name remediation

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1396 and its AUnit coverage.

Selected concrete remaining gap:

  Remaining_Update_Expression_Target_Name_Edge

The pass remediates an Ada 2022 update-expression / target-name edge requiring one canonical semantic result across:

* target-name @ use only within a valid update-expression context
* update aggregate target availability
* component update association evidence
* expected target type preservation
* component type compatibility
* missing update-target rejection
* target-name outside update-expression rejection
* runtime range/predicate/accessibility check preservation
* warning-only preservation
* private/full-view indeterminate blockers
* stale update-target evidence rejection
* aggregate, assignment, expression, and diagnostic consumer agreement
* final readiness gap removal
* source/AST/type/update/target/consumer fingerprint freshness

The AUnit suite covers legal, illegal, runtime-check, warning-only, indeterminate, inventory-gate, final-gate, corpus-balance, consumer, and fingerprint cases.
