Pass1174 — Generic formal declaration AST repair legality

This pass adds Editor.Ada_Generic_Formal_AST_Repair_Legality.

The pass turns the generic repaired-coverage facts from Pass1147 into concrete generic-formal declaration AST repair facts.  It covers generic formal objects, formal types, formal subprograms, and formal packages.

A generic formal declaration is accepted only when parser-node repair, structural AST repair, source-span repair, token-only replacement, degradation replacement, name-binding metadata, type metadata, required staticness metadata for formal objects/types, required contract metadata for formal subprograms/packages, cross-unit metadata, and integrated generic semantic consumer evidence are all present.  Missing parser nodes, structural AST shape, spans, name/type/staticness/contract/cross-unit metadata, consumer evidence, token-only parsing, graceful-degradation-only paths, and multiple blockers remain explicit semantic blockers.

The pass adds Test_Ada_Generic_Formal_AST_Repair_Legality_Pass1174 and registers it in the core AUnit suite.
