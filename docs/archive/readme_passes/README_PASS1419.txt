Pass1419 - Remaining_Protected_Action_Reentrancy_Edge

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1419 and the matching AUnit package Test_Ada_RM_Remaining_Gap_Remediation_Pass1419.

Selected concrete remaining gap:
Remaining_Protected_Action_Reentrancy_Edge

Coverage added:
- source-shaped legal closure for protected action reentrancy, self-calls, entry calls, requeue/select interactions, runtime protected-action checks, warning diagnostics, stale protected-action evidence, and semantic consumers
- illegal rejection outcomes with one stable blocker family: RM.Protected.Action.Reentrancy
- runtime-check preservation and warning-only preservation
- private/full-view and missing/stale evidence indeterminate blockers
- diagnostic consumer agreement
- final readiness gap removal evidence
- source, AST, type, profile, domain-specific, effect, and consumer fingerprint freshness gates
