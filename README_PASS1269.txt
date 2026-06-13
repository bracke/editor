Pass1269 implements Editor.Ada_Elaboration_RM_Completion_Closure_Consumer_Legality.

This pass makes elaboration legality consume the stabilized RM-completion closure directly, together with the direct RM-completion closure consumers for cross-unit closure, overload/type resolution, representation/freezing, tasking/protected legality, and dataflow/initialization. It preserves blocker-family identity for stabilized closure blockers, cross-unit closure consumers, overload/type consumers, representation/freezing consumers, tasking/protected consumers, dataflow consumers, source/substitution fingerprint mismatches, multiple prerequisites, and indeterminate state.

It also restores the pass1266 tasking/protected RM-completion closure consumer source package so the existing pass1266 test has its semantic package implementation in the snapshot.
