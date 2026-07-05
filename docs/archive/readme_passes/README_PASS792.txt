# Editor pass792 - abort statement terminator recovery depth

Pass792 deepens Ada abort-statement grammar metadata.

Changes:
- Added `Production_Abort_Terminator`.
- Added `Production_Abort_Missing_Terminator_Recovery_Boundary`.
- Well-formed abort statements now retain an abort-specific semicolon marker.
- Malformed or in-progress abort statements that reach a body boundary without a visible semicolon now retain bounded abort-specific recovery metadata.
- Preserved existing abort metadata for target lists, selected targets, indexed targets, dereferenced targets, separators, and shared recovery points.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Abort_Terminator_Recovery_Pass792`.
- Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage and bounded recovery for Ada abort statements. It is not compiler-grade tasking legality checking, task-name resolution, abortability legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
