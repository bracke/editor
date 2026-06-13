Editor Phase 579 pass772

Pass772 adds a bounded parser-owned diagnostic for call association-list ordering. Calls that retain a top-level positional actual after a named association now emit `Legality_Positional_Call_Actual_After_Named`, while duplicate named-call-actual diagnostics remain preserved.

Regression coverage:
- `Test_Language_Model_Legality_Call_Positional_After_Named_Pass772`

Updated guards and docs:
- README.md
- docs/ada_parser_coverage_matrix.md
- docs/release/RELEASE_CHECKLIST.md
- tools/phase579_language_validation_check.adb

This improves conservative local diagnostics for Ada call association-list shape. It is not compiler-grade overload resolution, callable profile matching, default-parameter legality checking, parameter mode checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
