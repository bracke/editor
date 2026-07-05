Editor pass781 - if-expression else recovery depth

This pass deepens structural parsing for Ada conditional expressions.  The token cursor now emits Production_If_Expression_Missing_Else_Recovery_Boundary when an if expression reaches its surrounding boundary without an else-dependent expression, while preserving existing conditional-expression, condition, then-dependent, else-dependent, and branch-expression metadata for well-formed forms.

AUnit coverage added:
- Test_Language_Model_Token_Cursor_If_Expression_Else_Recovery_Pass781

Updated files include:
- src/core/editor-ada_token_cursor.ads
- src/core/editor-ada_token_cursor.adb
- tests/src/editor-syntax_semantics-tests.adb
- README.md
- README_PASS781.txt
- docs/ada_parser_coverage_matrix.md
- docs/release/RELEASE_CHECKLIST.md
- tools/language_validation_check.adb

This improves structural grammar coverage and bounded recovery for Ada if expressions.  It is not compiler-grade conditional-expression legality checking, type resolution, expected-type analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
