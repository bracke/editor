Pass1271: Exception/finalization RM-completion closure consumer

This pass adds Editor.Ada_Exception_Finalization_RM_Completion_Closure_Consumer_Legality.

The pass makes exception/finalization legality consume the stabilized RM-completion closure directly, together with the direct RM-completion closure consumers for cross-unit closure, elaboration, accessibility/lifetime, overload/type resolution, representation/freezing, tasking/protected effects, and dataflow/initialization.

It preserves blocker-family identity for stabilized closure blockers, cross-unit blockers, elaboration blockers, accessibility/lifetime blockers, overload/type blockers, representation/freezing blockers, tasking/protected blockers, dataflow blockers, source/substitution fingerprint mismatches, multiple blockers, and indeterminate states.

Added AUnit coverage in Test_Ada_Exception_Finalization_RM_Completion_Closure_Consumer_Legality_Pass1271.
