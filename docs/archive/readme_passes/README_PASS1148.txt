Pass1148 - AST coverage repair gate application

This pass applies the parser/AST coverage repair facts from Pass1147 to the widened legality coverage-gate enforcement model from Pass1137.

The new package Editor.Ada_AST_Coverage_Repair_Gate_Application consumes repair rows and enforcement rows by stable node identity.  Matching complete repairs now clear parser/AST, semantic metadata, semantic-consumer, suppressed-legal, suppressed-derived, and unsafe-result coverage blockers.  Missing, partial, mismatched, cross-unit, and original semantic-error cases remain explicit blockers, so repair cannot silently hide unresolved semantic unsafety.

The model preserves repair row identity, enforcement row identity, widened legality engine, semantic conclusion family, construct/consumer, gate status/action, source node/span, messages, and deterministic fingerprints.  It performs no parsing, file IO, dirty-state mutation, render-side parsing, command/keybinding/workspace/render mutation, compiler invocation, or external parser generation.

Added regression test:
- Test_Ada_AST_Coverage_Repair_Gate_Application_Pass1148

This is a semantic integration pass: repaired Ada 2022 grammar/AST/metadata/consumer coverage now participates in the same widened legality gate path that previously suppressed unsafe conclusions.
