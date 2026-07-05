Pass1194 - Final semantic diagnostic integration

This pass adds Editor.Ada_Final_Semantic_Diagnostic_Integration.

The new package converts the final semantic closure and final semantic consumer chain into diagnostic-ready rows without flattening the original legality family. Legal final rows are withheld as non-diagnostic evidence; real blockers remain classified by source family: cross-unit closure, overload/type resolution, generic replay, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, and discriminant/variant integration.

The pass consumes final semantic evidence from:

* Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality
* Editor.Ada_Overload_Type_Final_RM_Consumer_Legality
* Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality
* Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality
* Editor.Ada_Flow_Contract_Final_Proof_Legality
* Editor.Ada_Tasking_Protected_Deep_Edge_Legality
* Editor.Ada_Elaboration_Graph_Final_Consumer_Legality
* Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality
* Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality

It preserves stale input, view barriers, AST repair blockers, coverage-gate blockers, indeterminate states, and multiple-blocker states as distinct outcomes instead of treating every final semantic failure as one generic diagnostic.

Added regression:

* Test_Ada_Final_Semantic_Diagnostic_Integration_Pass1194

This is semantic diagnostic integration only: it does not add UI/status/projection behaviour and does not mutate buffers, rendering, commands, keybindings, workspace state, or files during analysis.
