# Editor — Pass1145

Pass1145 adds `Editor.Ada_Tasking_Protected_Effects_Legality`, a widened compiler-grade building block for tasking/protected semantic effects.

The pass deepens the existing tasking/protected precision layer by modelling task activation and termination effects, protected-object read/write effects, entry queue state, accept-body state effects, requeue target/open/abort safety, select guard and alternative reachability, abortable-part finalization hazards, delay alternative staticness, and terminate alternative restrictions.

The model consumes and preserves blockers from:

* `Editor.Ada_Tasking_Protected_Precision_Legality`
* `Editor.Ada_Flow_Effect_Graph_Legality`
* `Editor.Ada_Elaboration_Graph_Closure_Legality`
* `Editor.Ada_Accessibility_Scope_Graph_Legality`
* `Editor.Ada_Exception_Finalization_Legality`
* `Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement`

This keeps tasking/protected conclusions from becoming confident when flow, elaboration, accessibility, finalization, or parser/AST coverage gates block them.

AUnit coverage is added in `Test_Ada_Tasking_Protected_Effects_Legality_Pass1145` and registered in `tests/src/core_suite.adb`.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
