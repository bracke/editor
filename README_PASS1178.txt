Pass1178 - Ada expression construct AST repair legality

This pass adds Editor.Ada_Expression_Construct_AST_Repair_Legality.

The pass provides concrete parser/AST repair legality for Ada 2022 expression constructs whose earlier coverage gates could otherwise force widened semantic results to remain indeterminate. It covers container aggregates, delta aggregates, reduction expressions, and quantified expressions.

A construct is treated as restored only when the corresponding repaired coverage facts show parser node repair, structural AST repair, source-span repair, token-only parse replacement, graceful-degradation replacement, name/type/staticness/contract/flow/representation/cross-unit metadata repair, and integrated expression/overload/predicate/contract/flow/aggregate consumer evidence.

This pass adds one compiler-grade building block for expression legality. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.

AUnit: Test_Ada_Expression_Construct_AST_Repair_Legality_Pass1178
