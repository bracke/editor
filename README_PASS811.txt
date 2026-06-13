Editor Phase 579 pass811 - Object declaration terminator recovery depth

This pass improves structural Ada grammar coverage for object declarations.

Changes:
- Added Production_Object_Declaration_Terminator.
- Added Production_Object_Declaration_Missing_Terminator_Recovery_Boundary.
- Ordinary object declarations now retain object-specific semicolon metadata.
- Object declarations with initializers and trailing aspects preserve their existing initialization/aspect metadata.
- In-progress object declarations missing a visible semicolon now retain bounded recovery metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Object_Declaration_Terminator_Pass811.
- Updated validation guards and parser coverage documentation.

This is structural parser metadata only. It is not compiler-grade object declaration legality checking, subtype compatibility checking, initialization legality checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
