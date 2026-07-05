Pass1177 — Discriminant / variant AST repair legality

This pass adds Editor.Ada_Discriminant_Variant_AST_Repair_Legality.

The pass turns repaired-coverage facts from Pass1147 into concrete discriminant/variant parser-AST repair facts. It covers discriminant specifications, variant parts, discriminant-dependent aggregate contexts, and private/full-view discriminant view contexts.

A discriminant/variant construct is accepted only when parser-node repair, structural AST repair, source-span repair, token-only replacement, degradation replacement, name-binding metadata, type metadata, required staticness metadata for discriminants and variants, required contract metadata for dependent aggregate/view contexts, flow metadata, representation/freezing metadata, cross-unit metadata, and integrated discriminant/aggregate/accessibility/representation consumer evidence are all present. Missing parser nodes, structural AST shape, spans, metadata, consumer evidence, token-only parsing, graceful-degradation-only paths, mismatches, and multiple blockers remain explicit semantic blockers.

This pass adds one compiler-grade building block for discriminant/variant AST repair. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.

The pass adds Test_Ada_Discriminant_Variant_AST_Repair_Legality_Pass1177 and registers it in the core AUnit suite.
