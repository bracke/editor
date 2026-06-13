Editor phase579 IDE-grade outline/semantic language model pass421

Implemented a parser-completeness pass for Ada extended return statements.

Changes:
- Added Production_Return_Object_Declaration to Editor.Ada_Token_Cursor.
- Added Production_Extended_Return_Initializer to Editor.Ada_Token_Cursor.
- Parsed extended return object declarations structurally after `return`: defining name, colon, optional aliased, optional constant, subtype indication, optional initializer, and `do` statement sequence.
- Added AUnit regression coverage for `return Result : aliased constant Item := Make_Item (1) do`.
- Updated validation guards, release guard comments, README, outline docs, syntax-colouring docs, and release checklist.

This is grammar retention only. It does not implement compiler-grade return-object conformance, limited/build-in-place legality, accessibility, or subtype legality checks.
