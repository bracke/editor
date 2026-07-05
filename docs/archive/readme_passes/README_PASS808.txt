Editor pass808 — entry declaration terminator recovery depth

This pass adds entry-declaration-specific terminator and missing-terminator recovery metadata to the Ada token cursor.

Changed:
- Added Production_Entry_Terminator.
- Added Production_Entry_Missing_Terminator_Recovery_Boundary.
- Entry declarations now retain a visible semicolon marker after optional entry aspects.
- Entry declarations that reach a protected/task declaration boundary without a semicolon now emit bounded entry-specific recovery metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Entry_Declaration_Terminator_Recovery_Pass808.
- Updated validation/release guards and parser coverage docs.

Scope:
- Improves structural grammar coverage for Ada entry declarations.
- Does not implement compiler-grade entry-family legality, protected/task conformance checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.
