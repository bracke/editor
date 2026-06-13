Pass1426 - Remaining_Inherited_Private_Extension_Primitive_Hiding_Edge

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1426 and the matching AUnit package Test_Ada_RM_Remaining_Gap_Remediation_Pass1426.

Selected concrete remaining gap:
Remaining_Inherited_Private_Extension_Primitive_Hiding_Edge

Coverage added:
- source-shaped legal closure for inherited primitives of private extensions, primitive hiding and overriding, interface primitive conflicts, dispatching candidate visibility, runtime dispatching checks, warning diagnostics, stale primitive-hiding evidence, and semantic consumers
- illegal rejection outcomes with one stable blocker family: RM.Tagged.Private_Extension.Primitive_Hiding
- runtime-check preservation and warning-only preservation
- private/full-view and missing/stale evidence indeterminate blockers
- diagnostic consumer agreement
- final readiness gap removal evidence
- source, AST, type, profile, domain-specific, effect, and consumer fingerprint freshness gates
