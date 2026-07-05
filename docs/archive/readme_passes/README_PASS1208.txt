Pass1208 - Final Semantic Stabilization Gate Legality

This pass adds Editor.Ada_Final_Semantic_Stabilization_Gate_Legality.

The package consumes Pass1207 final semantic recheck convergence rows and turns them into a stabilization gate for the final closure/feed boundary. A semantic result is promoted only when the recheck result has converged and its prerequisite evidence is stable. Rows that are still withheld by stale evidence, AST/coverage gaps, cross-unit dependencies, view barriers, generic replay/backmapping, overload/type evidence, representation/freezing evidence, flow/contract proof, tasking/protected effects, elaboration evidence, accessibility/lifetime evidence, discriminant/variant evidence, multiple prerequisites, or indeterminate state remain explicit blockers.

The pass preserves blocker-family identity and stable fingerprints so downstream semantic consumers can distinguish promoted current results from withheld prerequisite-blocked results and recheck-required results.

Added test:
- Test_Ada_Final_Semantic_Stabilization_Gate_Legality_Pass1208

Updated:
- tests/src/core_suite.adb
- README.md
- ada_parser_coverage_matrix.md
- syntax_colouring_notes.md
- release_checklist.md
- strict_runtime_validation.md
