Pass1420 - Remaining_Volatile_Atomic_Representation_Clause_Edge

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1420 and the matching AUnit package Test_Ada_RM_Remaining_Gap_Remediation_Pass1420.

Selected concrete remaining gap:
Remaining_Volatile_Atomic_Representation_Clause_Edge

Coverage added:
- source-shaped legal closure for volatile and atomic representation clauses, size/alignment evidence, full-access and independent-addressability evidence, freezing, runtime representation checks, warning diagnostics, stale representation evidence, and semantic consumers
- illegal rejection outcomes with one stable blocker family: RM.Representation.Volatile_Atomic.Clause
- runtime-check preservation and warning-only preservation
- private/full-view and missing/stale evidence indeterminate blockers
- diagnostic consumer agreement
- final readiness gap removal evidence
- source, AST, type, profile, domain-specific, effect, and consumer fingerprint freshness gates
