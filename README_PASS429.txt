Editor Phase 579 pass429 - Ada box-expression parser grammar

Implemented another parser-completeness pass.

Changes:
- Added Production_Box_Expression to Editor.Ada_Token_Cursor.
- Retained Ada box expressions <> as expression primaries instead of opaque operators.
- Covered aggregate association boxes such as (others => <>).
- Covered generic actual association boxes such as Element => <>.
- Added AUnit regression Test_Language_Model_Token_Cursor_Box_Expression_Grammar_Completeness.
- Updated validation/release guards and documentation notes.

Non-goals retained:
- No compiler-grade expected-type resolution for boxes.
- No aggregate completeness or generic actual legality checking.
- No semantic validation beyond bounded structural parser retention.
