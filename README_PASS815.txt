### Pass815 - Exception declaration terminator recovery depth

Pass815 deepens Ada exception declaration completion metadata. Ordinary exception declarations now retain `Production_Exception_Declaration_Terminator` when their visible semicolon is present and `Production_Exception_Declaration_Missing_Terminator_Recovery_Boundary` when a declaration reaches the next synchronization token without its own terminator. Attached aspect metadata remains preserved for declarations such as `E : exception with Convention => Ada;`, and recovery leaves following declarations visible.

Changed:
- Added exception-declaration-specific terminator metadata.
- Added bounded missing-terminator recovery metadata for malformed/in-progress ordinary exception declarations.
- Added parser helper `Parse_Exception_Declaration_Aspect_Or_Terminator` to avoid relying on the generic aspect/semicolon helper for exception declaration completion.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Exception_Declaration_Terminator_Pass815`.
- Updated README, coverage matrix, syntax-colouring notes, release checklist, and phase579 validation guards.

This improves structural grammar coverage for Ada exception declaration completion. It is not compiler-grade exception renaming legality, aspect legality checking, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

