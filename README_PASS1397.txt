Pass1397 - Remaining expression-function contract/return remediation

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1397 and a focused
AUnit suite.  It remediates the concrete remaining gap
Remaining_Expression_Function_Contract_Return_Edge.

The pass requires expression-function return expressions, return result typing,
Pre/Post contract evidence, No_Return flow evidence, runtime checks, warning-only
policy evidence, private/full-view blockers, stale contract evidence rejection,
semantic consumer surfacing, and final readiness gap removal to agree as one
canonical source-shaped result.

Coverage includes legal, illegal, legal-with-runtime-check, warning-only,
indeterminate, inventory/final-gate, consumer, and fingerprint cases.
