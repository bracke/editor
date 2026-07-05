Editor pass932 — Formal package declaration header recovery

This pass improves structural Ada grammar coverage for generic formal package declarations.

Changes:
- Added token-cursor recovery productions for formal package declarations missing `is` or `new`.
- Added recovery metadata for positional formal package actual associations that appear after named associations.
- Preserved `(<>)`, defaulted actual parts, and following generic formal declarations after malformed formal package headers.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Formal_Package_Header_Recovery_Pass932`.
- Updated parser coverage notes, semantic-colouring notes, release checklist, validation guards, and README.

Scope:
This improves structural grammar coverage for formal package declarations. It is not compiler-grade generic contract checking, generic actual conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
