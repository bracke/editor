Editor Phase 579 pass797 - goto statement terminator recovery depth

This pass deepens Ada goto-statement grammar metadata in the token cursor.

Changed:
- Added Production_Goto_Missing_Terminator_Recovery_Boundary.
- Well-formed goto statements continue to retain Production_Goto_Terminator for visible semicolons.
- Malformed or in-progress goto statements that reach a body/select boundary without a visible semicolon now emit bounded goto-specific recovery metadata.
- Preserved existing goto target, label-name, label recovery, and shared recovery metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Goto_Terminator_Recovery_Pass797.
- Updated validation/release guards and parser coverage docs.

Scope note:
This improves structural grammar coverage and bounded recovery for Ada goto statements. It is not compiler-grade label resolution, control-flow legality checking, visibility checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
