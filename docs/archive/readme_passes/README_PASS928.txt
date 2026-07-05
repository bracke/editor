Editor — Pass928

This pass improves structural Ada grammar recovery for malformed array index parts.

Implemented:
- Added Production_Array_Index_Reserved_Boundary_Recovery_Boundary.
- Refined array index-part parsing so reserved/declaration boundaries are not fabricated as array index items or upper-bound expressions.
- Covered malformed forms such as:
  - type Missing_Item is array (else) of Integer;
  - type Missing_Upper is array (1 .. else) of Integer;
- Preserved array type definition metadata, generic constraint recovery metadata, and valid following array index upper-bound metadata.

Regression:
- Added Test_Language_Model_Token_Cursor_Array_Index_Reserved_Boundary_Recovery_Pass928.

Updated:
- src/core/editor-ada_token_cursor.ads
- src/core/editor-ada_token_cursor.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/language_validation_check.adb
- docs/ada_parser_coverage_matrix.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
- README.md

This is editor-grade structural grammar coverage. It is not compiler-grade array index subtype legality checking, range expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
