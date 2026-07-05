pass 435 - discriminant constraint grammar

Implemented another Ada token-cursor parser-completeness pass.

Changes:
- Added Production_Discriminant_Constraint to Editor.Ada_Token_Cursor.
- Added Production_Discriminant_Association to Editor.Ada_Token_Cursor.
- Added named-discriminant constraint parsing for subtype indications such as Bounds (Low => 1, High => 10).
- Kept ordinary array index constraints on Production_Index_Constraint for forms such as Table (1 .. 5).
- Added AUnit coverage via Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness.
- Updated validation/release guard comments and parser documentation notes.

Limitations:
- This is syntax retention only.
- Positional constraints remain conservatively parsed as index constraints because they cannot be distinguished from array index constraints without symbol knowledge.
- Compiler-grade discriminant legality, subtype conformance, full/private view matching, and constraint compatibility remain outside the editor parser.
