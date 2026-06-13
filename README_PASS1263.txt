Pass1263: Generic/shared-state RM-completion stabilized closure

This pass adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality.

It consumes Pass1262 generic/shared-state RM-completion stabilization-gate rows and promotes stable accepted rows into first-class semantic closure evidence. Stable blocked rows remain explicit closure blockers with their original blocker-family identity preserved, including stale/fingerprint, AST/coverage, cross-unit, generic substitution, prior dataflow, volatile/atomic, overload/type, representation/freezing, tasking/protected, elaboration, accessibility, discriminant/variant, exception/finalization, renaming/alias, predicate/invariant, dataflow, multiple-prerequisite, and indeterminate blockers.

The pass provides deterministic row counts, accepted/current/blocked/recheck/indeterminate counters, blocker-family and status queries, node/source/substitution-fingerprint lookups, and a stable closure fingerprint.

Regression coverage is added in Test_Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality_Pass1263 and registered in tests/src/core_suite.adb.
