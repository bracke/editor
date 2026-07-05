Editor pass789 — timed / conditional entry-call select depth

This pass deepens token-cursor metadata for Ada timed and conditional entry-call statements.

Changes:
- Added Production_Timed_Entry_Call_Statement.
- Added Production_Timed_Entry_Call_Entry_Call_Part.
- Added Production_Conditional_Entry_Call_Statement.
- Added Production_Conditional_Entry_Call_Entry_Call_Part.
- Entry-call alternatives inside select statements with delay alternatives now retain timed-entry-call statement metadata.
- Entry-call alternatives inside select statements with else parts now retain conditional-entry-call statement metadata.
- Preserved existing selected-entry-call, entry-call target, actual-part, delay, and else-part metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Timed_Conditional_Entry_Call_Pass789.
- Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage for Ada timed and conditional entry-call statements. It is not compiler-grade tasking legality checking, entry-call resolution, delay legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
