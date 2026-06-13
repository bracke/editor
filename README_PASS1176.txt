Pass1176 — Representation / operational clause AST repair legality

This pass adds Editor.Ada_Representation_Operational_AST_Repair_Legality.

The pass turns repaired-coverage facts from Pass1147 into concrete representation/operational parser-AST repair facts. It covers representation clauses, operational attribute clauses, aspect specifications, and pragmas.

A representation/operational construct is accepted only when parser-node repair, structural AST repair, source-span repair, token-only replacement, degradation replacement, name-binding metadata, type metadata, required staticness metadata for representation and operational clauses, required contract metadata for aspects and pragmas, flow metadata, representation/freezing metadata, cross-unit metadata, and integrated representation/contract/elaboration consumer evidence are all present. Missing parser nodes, structural AST shape, spans, metadata, consumer evidence, token-only parsing, graceful-degradation-only paths, mismatches, and multiple blockers remain explicit semantic blockers.

This pass adds one compiler-grade building block for representation/operational AST repair. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.

The pass adds Test_Ada_Representation_Operational_AST_Repair_Legality_Pass1176 and registers it in the core AUnit suite.
