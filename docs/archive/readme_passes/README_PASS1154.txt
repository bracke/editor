Pass1154 - Integrated closure for Refined_Global / Refined_Depends conformance

This pass adds Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends.

The new child package consumes Editor.Ada_Refined_Global_Depends_Conformance_Legality rows and injects them into integrated semantic closure as first-class semantic closure contexts.

Legal refined Global/Depends body-spec rows remain legal local closure rows. Missing Global coverage, Refined_Global mode or coverage errors, Refined_Depends missing/extra/source/target errors, unpropagated call effects, linked flow-effect blockers, repaired coverage blockers, and other non-legal refined conformance rows become Integrated_Closure_Refined_Global_Depends_Blocker rows with Closure_Blocker_Refined_Global_Depends.

This makes the Pass1153 checker a real closure consumer: refined flow-contract failures no longer stop at the isolated checker layer, and downstream closure diagnostics/index/provenance consumers can see them through the existing integrated closure model.

AUnit regression added:
Test_Ada_Integrated_Closure_Refined_Global_Depends_Pass1154

Updated:
- tests/src/core_suite.adb
- README.md
- docs/ada_parser_coverage_matrix.md
- docs/syntax_colouring.md
- docs/syntax_colouring_notes.md
- docs/strict_runtime_validation.md
- docs/release/checklist.md
- docs/release/RELEASE_CHECKLIST.md
- docs/release/RELEASE_STATE.txt
- docs/release/STRICT_RUNTIME_VALIDATION.md
- docs/release/STRICT_RUNTIME_VALIDATION_RECORD.md
