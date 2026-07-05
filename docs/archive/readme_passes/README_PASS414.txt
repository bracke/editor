pass 414 — unconstrained array index subtype grammar

This pass extends the Ada token-cursor parser with explicit grammar retention for unconstrained array index subtype definitions.

Implemented:
- Added Production_Index_Subtype_Definition to Editor.Ada_Token_Cursor.
- Added Parse_Array_Index_Part for array type definitions.
- Distinguishes unconstrained array domains such as Positive range <> from constrained index/range constraints.
- Preserves constrained array parsing for forms such as array (1 .. 10) of T.
- Added AUnit coverage in Test_Language_Model_Token_Cursor_Array_Index_Subtype_Grammar_Completeness.
- Updated validation/release guards and docs.

Limits:
- This is grammar recognition only.
- The editor still does not perform compiler-grade array index legality, discrete subtype legality, constraint compatibility, or expected-type resolution.
