Pass1398 - Remaining conditional-expression expected-type gap remediation

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1398 and the matching AUnit suite.

Selected concrete remaining gap:

  Remaining_Conditional_Expression_Expected_Type_Edge

This pass remediates a conditional-expression semantic edge requiring agreement across:

  * if-expression and case-expression expected-type propagation
  * branch expression availability
  * branch result type compatibility
  * Boolean guard legality
  * static case-choice overlap rejection
  * runtime range/predicate/accessibility check preservation
  * warning-only preservation
  * private/full-view indeterminate blockers
  * stale conditional/branch evidence rejection
  * expression, assignment/conversion, control-flow, contract, and diagnostic consumer agreement
  * final readiness gap removal
  * source/AST/type/conditional/branch/consumer fingerprint freshness

The tests include legal, illegal, runtime-check, warning-only, indeterminate, inventory-gate, final-gate, corpus-balance, consumer, and fingerprint scenarios.
