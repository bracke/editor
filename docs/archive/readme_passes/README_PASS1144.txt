# Pass1144 - Elaboration graph closure legality

Pass1144 adds `Editor.Ada_Elaboration_Graph_Closure_Legality`, a compiler-grade building block that deepens elaboration/dependence precision into an explicit library-unit elaboration graph closure model.

The pass connects transitive `Elaborate_All` closure, body-before-use through direct and indirect calls, dispatching-call elaboration order, access-before-elaboration risks, generic instance elaboration, default/aspect/representation elaboration edges, policy restrictions for preelaborated/pure/remote/shared-passive units, flow-effect graph blockers, accessibility scope graph blockers, generic replay blockers, precision blockers, base elaboration blockers, and coverage-gated semantic results.

The package remains snapshot-owned and deterministic. It performs no parsing, file IO, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, external parser generation, Python, or shell-script work.

Added regression coverage:

* `Test_Ada_Elaboration_Graph_Closure_Legality_Pass1144`

This pass adds one compiler-grade building block for elaboration graph closure. Full compiler-grade Ada analysis remains incomplete until remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
