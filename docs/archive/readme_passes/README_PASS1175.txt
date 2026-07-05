Pass1175 — Access definition AST repair legality

This pass adds Editor.Ada_Access_Definition_AST_Repair_Legality.

The pass turns the repaired-coverage facts from Pass1147 into concrete access-definition parser/AST repair facts.  It covers object access definitions, anonymous access parameters, access-to-subprogram definitions, and access discriminants.

An access definition is accepted only when parser-node repair, structural AST repair, source-span repair, token-only replacement, degradation replacement, name-binding metadata, type metadata, required staticness metadata, required contract metadata for access-to-subprogram and access-discriminant contexts, flow metadata, representation/freezing metadata, cross-unit metadata, and integrated accessibility/access consumer evidence are all present.  Missing parser nodes, structural AST shape, spans, name/type/staticness/contract/flow/representation/cross-unit metadata, consumer evidence, token-only parsing, graceful-degradation-only paths, and multiple blockers remain explicit semantic blockers.

This pass adds one compiler-grade building block for access-definition AST repair.  Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.

The pass adds Test_Ada_Access_Definition_AST_Repair_Legality_Pass1175 and registers it in the core AUnit suite.
