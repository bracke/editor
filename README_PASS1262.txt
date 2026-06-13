Pass1262 — Generic/shared-state RM-completion stabilization gate

This pass adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality.

The pass consumes Pass1261 RM-completion recheck convergence rows and decides whether the combined generic/shared-state RM-completion chain may cross the stable semantic boundary. Stable current and not-required rows are promoted. Stable prerequisite blockers remain withheld with their original blocker-family identity. Changed fingerprints force another bounded recheck. Indeterminate rows remain degraded instead of becoming confident legality evidence.

The gate preserves distinct blocker families for stale/fingerprint evidence, AST/coverage repair, cross-unit RM-completion closure, generic substitution, prior dataflow, volatile/atomic/shared-state effects, overload/type, representation/freezing, tasking/protected, elaboration, accessibility/lifetime, discriminants/variants, exception/finalization, renaming/alias, predicate/invariant, dataflow, multiple prerequisites, and indeterminate states.

Added regression:

Test_Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality_Pass1262

This pass adds one compiler-grade building block for stabilizing the RM-completed generic/shared-state semantic chain. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
