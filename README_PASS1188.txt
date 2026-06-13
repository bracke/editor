Pass1188 - Expression control/target AST repair legality

This pass adds Editor.Ada_Expression_Control_Target_AST_Repair_Legality.

Purpose:
- Add concrete parser/AST repair legality for expression-control and target-name constructs that still gate real semantic consumers.
- Cover membership tests, case expressions, if expressions, declare expressions, and target-name / update-expression contexts.
- Treat these constructs as semantically restored only when parser-node repair, structural AST repair, source-span repair, token-only/degradation replacement, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, and integrated expression/control-flow/overload/predicate/contract/dataflow consumers are present.

Semantic effect:
- Missing parser nodes, structural shape, source spans, token-only fallback, graceful-degradation fallback, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, missing consumers, and non-integrated consumers remain explicit blockers.
- Complete repairs are converted into accepted repair rows with stable fingerprints.
- Repair rows can be built directly from context rows or aggregated from Editor.Ada_AST_Coverage_Repair_Legality repair facts by syntax node.

Regression:
- Added Test_Ada_Expression_Control_Target_AST_Repair_Legality_Pass1188.
- Registered the test in tests/src/core_suite.adb.

This pass adds one compiler-grade building block for parser/AST repair of expression-control and target-name constructs. Full compiler-grade Ada analysis remains incomplete until remaining overload/type resolution edge cases, cross-unit generic replay cycles, representation/freezing hard cases, flow/contract proof strengthening, volatile/atomic semantics, tasking/protected deep edge cases, and final blocker-preserving diagnostic integration are fully integrated.
