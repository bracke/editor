Pass1187 - Renaming, separate-body, and exception AST repair legality

This pass adds Editor.Ada_Renaming_Separate_Exception_AST_Repair_Legality.

Purpose:
- Turn generic repaired-coverage rows into concrete semantic repair facts for renaming declarations, separate bodies, body stubs, exception handlers, and raise expressions.
- Prevent these constructs from regaining confident legality unless parser nodes, structural AST shape, source spans, token-only/degradation replacement, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, and integrated semantic consumers are present.
- Reduce false positives in the repaired/gated semantic chain by preserving construct-specific blockers instead of treating repaired coverage as a generic success.

Implemented semantics:
- Accepted repair states for renaming declarations, separate bodies, body stubs, exception handlers, and raise expressions.
- Parser-node, structural-AST, source-span, token-only parse, and graceful-degradation blockers.
- Name-binding, type, staticness, contract, flow, representation/freezing, and cross-unit metadata blockers.
- Semantic-consumer missing and semantic-consumer-not-integrated blockers.
- Multiple-blocker and indeterminate repair states.
- Deterministic row identity, node lookup, status/construct filtering, counters, and fingerprints.
- Aggregation from Editor.Ada_AST_Coverage_Repair_Legality repair rows into construct-specific repair contexts.

Added regression:
- Test_Ada_Renaming_Separate_Exception_AST_Repair_Legality_Pass1187

Updated:
- tests/src/core_suite.adb
- README_PASS1187.txt
- README.md
- ada_parser_coverage_matrix.md
- syntax_colouring_notes.md
- release_checklist.md
- strict_runtime_validation.md
- docs/ada_parser_coverage_matrix.md
- docs/syntax_colouring_notes.md
- docs/release_checklist.md
- docs/strict_runtime_validation.md
- docs/release/RELEASE_CHECKLIST.md
- docs/release/STRICT_RUNTIME_VALIDATION.md

This pass adds one compiler-grade building block for parser/AST repair gating of renaming, separate-body, and exception constructs. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
