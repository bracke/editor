Pass417 parser-completeness update

- Added Production_Target_Name to Editor.Ada_Token_Cursor.
- Added Ada 2022 target_name primary recognition for @ inside expressions.
- Added regression coverage for assignment expressions using @ directly and as an actual parameter.
- Updated validation/release guards and docs.

This is syntax retention, not compiler-grade legality checking. The parser does not validate that @ appears only where Ada legality permits it, nor does it check assignability or type resolution.
