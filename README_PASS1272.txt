Pass1272 - Predicate RM-completion closure consumer legality

Implemented Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality.

This pass makes predicate/invariant legality consume the Pass1263 stabilized RM-completion closure directly. It also requires the direct RM-completion closure consumers for cross-unit closure, elaboration, accessibility/lifetime, exception/finalization, overload/type resolution, representation/freezing, tasking/protected legality, and dataflow/initialization before predicate and invariant conclusions are accepted as current.

The pass preserves blocker-family identity for prior predicate RM evidence, stabilized closure blockers, cross-unit blockers, elaboration blockers, accessibility blockers, exception/finalization blockers, overload/type blockers, representation/freezing blockers, tasking/protected blockers, dataflow blockers, source/substitution fingerprint mismatches, multiple blockers, and indeterminate state.

Added AUnit coverage in Test_Ada_Predicate_RM_Completion_Closure_Consumer_Legality_Pass1272 and registered it in the core suite.
