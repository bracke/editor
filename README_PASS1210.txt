Pass1210 - Final stabilized semantic diagnostic integration

This pass adds Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.

Purpose
-------
Pass1209 made stabilization-gate results first-class stabilized semantic closure rows. Pass1210 connects those stabilized closure rows back to the final diagnostic/feed boundary while preserving blocker-family identity and withholding stable accepted closure rows as non-diagnostic current semantic evidence.

This is not a UI projection/status layer. It consumes already-built stabilized closure rows and classifies whether each row is:

* withheld as accepted current closure,
* withheld as accepted not-required closure,
* emitted as a stable blocker,
* retained as a preserved semantic error,
* emitted as an indeterminate warning, or
* withheld/reported as recheck-required before feed promotion.

Preserved blocker families
--------------------------
Pass1210 keeps distinct blocker families for:

* stale snapshot evidence,
* AST / coverage repair gaps,
* cross-unit dependency closure,
* private/limited/full-view barriers,
* generic replay / source-instance backmapping,
* overload/type RM evidence,
* representation/freezing evidence,
* flow/contract proof evidence,
* tasking/protected effects,
* elaboration evidence,
* accessibility/lifetime evidence,
* discriminant/variant evidence,
* preserved semantic errors,
* multiple simultaneous prerequisites, and
* indeterminate states.

Files added
-----------

* src/core/editor-ada_final_semantic_stabilized_diagnostic_integration.ads
* src/core/editor-ada_final_semantic_stabilized_diagnostic_integration.adb
* Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Final_Stabilized_Diagnostics
* tests/src/test_ada_final_semantic_stabilized_diagnostic_integration_pass1210.ads
* tests/src/test_ada_final_semantic_stabilized_diagnostic_integration_pass1210.adb

Files updated
-------------

* tests/src/core_suite.adb
* README.md
* ada_parser_coverage_matrix.md
* syntax_colouring_notes.md
* release_checklist.md
* strict_runtime_validation.md
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring_notes.md
* docs/release_checklist.md
* docs/strict_runtime_validation.md
