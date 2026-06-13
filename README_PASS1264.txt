Pass1264 — Overload RM-completion closure consumer legality

This pass adds Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality.

The pass consumes the Pass1263 generic/shared-state RM-completion stabilized closure as first-class semantic evidence for overload/type RM edge consumers. Overload conclusions are accepted only when the prior overload RM-completion row is accepted, the stabilized RM-completion closure row is accepted, source and substitution fingerprints still match, and no closure blocker remains unresolved.

The consumer preserves blocker-family identity for prior overload RM evidence, stabilized closure evidence, stale/fingerprint evidence, AST/coverage repair, cross-unit closure, generic substitution, prior/dataflow, volatile/atomic shared state, representation/freezing, tasking/protected effects, elaboration, accessibility, discriminants/variants, exception/finalization, renaming/aliasing, predicates/invariants, multiple prerequisites, and indeterminate closure state.

Added regression:

Test_Ada_Overload_RM_Completion_Closure_Consumer_Legality_Pass1264

This pass adds one compiler-grade building block for overload/type consumers over the stabilized RM-completion closure. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
