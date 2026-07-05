Pass1173 — Tasking/protected/select AST repair legality

This pass adds Editor.Ada_Tasking_Protected_AST_Repair_Legality.

The pass turns the generic repaired-coverage facts from Pass1147 into concrete task/protected/select AST repair facts.  It covers task types and bodies, protected types and bodies, entry declarations and bodies, accept statements, requeue statements, and select statements.

A construct is accepted only when parser-node repair, structural AST repair, source-span repair, token-only replacement, degradation replacement, required flow metadata, required contract metadata for barrier/select/accept contexts, required representation metadata for task/protected declaration contexts, cross-unit metadata, and integrated tasking/protected consumer evidence are all present.  Missing parser nodes, structural AST shape, spans, flow/contract/representation/cross-unit metadata, consumer evidence, token-only parsing, graceful-degradation-only paths, and multiple blockers remain explicit semantic blockers.

The pass adds Test_Ada_Tasking_Protected_AST_Repair_Legality_Pass1173 and registers it in the core AUnit suite.
