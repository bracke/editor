Pass1270 implements Editor.Ada_Accessibility_RM_Completion_Closure_Consumer_Legality.

This pass makes accessibility/lifetime legality consume the Pass1263 stabilized RM-completion closure directly together with the direct RM-completion closure consumers for cross-unit closure, elaboration, overload/type resolution, representation/freezing, tasking/protected legality, and dataflow/initialization.

The consumer prevents accessibility conclusions for access values escaping through generics, renamings, discriminant-dependent components, dispatching access results, controlled/finalized objects, protected/task shared state, representation-sensitive lifetimes, and cross-unit object lifetimes from bypassing stabilized RM-completion evidence.

The pass preserves blocker-family identity for prior accessibility RM rows, stabilized closure blockers, cross-unit blockers, elaboration blockers, overload/type blockers, representation/freezing blockers, tasking/protected blockers, dataflow blockers, source/substitution fingerprint mismatches, multiple blockers, and indeterminate state.

Added AUnit coverage in Test_Ada_Accessibility_RM_Completion_Closure_Consumer_Legality_Pass1270 and registered it in core_suite.adb.
