Editor Phase 579 — Pass929

This pass improves structural Ada grammar recovery for malformed access-to-object definitions whose designated subtype is replaced by a reserved/declaration boundary.

Implemented:
- Added Production_Access_Object_Missing_Subtype_Recovery_Boundary.
- Refined access-to-object definition parsing so boundary tokens such as `with`, `is`, `begin`, `end`, `private`, `)`, end-of-input, and `;` are reported as missing designated subtype recovery points instead of being parsed as subtype marks.
- Preserved the existing shared Production_Access_Type_Recovery_Boundary metadata.
- Kept valid following declarations visible after recovery.

Regression:
- Added Test_Language_Model_Token_Cursor_Access_Object_Missing_Subtype_Recovery_Pass929 covering aspect-boundary, private-boundary, and delimiter-boundary malformed access-object definitions plus recovery into a following declaration.

Updated:
- src/core/editor-ada_token_cursor.ads
- src/core/editor-ada_token_cursor.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/phase579_language_validation_check.adb
- docs/ada_parser_coverage_matrix.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
- README.md

This improves editor-grade structural grammar coverage for access-to-object definitions. It is not compiler-grade access-type legality checking, designated-subtype legality checking, subtype resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
