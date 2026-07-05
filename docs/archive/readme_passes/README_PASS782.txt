Editor pass782 - case-expression recovery depth

This pass deepens structural parsing for Ada case expressions.  The token cursor now emits Production_Case_Expression_Missing_Arrow_Recovery_Boundary when a case-expression alternative has a choice list but no => token, and Production_Case_Expression_Missing_Alternative_Recovery_Boundary when a case expression reaches its local boundary without any when alternative.

AUnit coverage added:
- Test_Language_Model_Token_Cursor_Case_Expression_Recovery_Pass782

Updated files include:
- src/core/editor-ada_token_cursor.ads
- src/core/editor-ada_token_cursor.adb
- tests/src/editor-syntax_semantics-tests.adb
- README.md
- README_PASS782.txt
- docs/ada_parser_coverage_matrix.md
- docs/release/RELEASE_CHECKLIST.md
- tools/language_validation_check.adb

This improves structural grammar coverage and bounded recovery for Ada case expressions.  It is not compiler-grade case-expression legality checking, choice coverage checking, duplicate-choice analysis, expected-type analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
