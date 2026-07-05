Pass1249 - Coverage-proven generic/shared-state AST repair legality

This pass adds one compiler-grade building block for evidence-driven parser/AST repair.

New package:
Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality

Purpose:
Accept parser-node, structural AST, token-only parse, source-span, metadata, and consumer-integration repair as current semantic evidence only when semantic coverage gates prove that the construct is a real blocker for generic/shared-state final consumers. The pass rejects speculative parser repair when no coverage gate exists, when the gate is open, or when the gate does not require repair.

Consumed evidence:
- Editor.Ada_Semantic_Coverage_Gates
- Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality
- Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality
- Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality
- Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality

The pass preserves blocker-family identity for missing coverage gates, non-repairable gates, stabilized closure blockers, overload RM edge blockers, representation/freezing RM hard-case blockers, tasking/protected RM hard-case blockers, unresolved parser-node gaps, unresolved structural AST gaps, token-only paths, missing source spans, missing metadata, missing consumer integration, fingerprint mismatches, multiple blockers, and indeterminate state.

Regression:
Test_Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality_Pass1249

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
