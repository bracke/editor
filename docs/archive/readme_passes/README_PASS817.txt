Pass817 - Generic formal declaration terminator recovery depth

- Added Production_Generic_Formal_Declaration_Terminator.
- Added Production_Generic_Formal_Declaration_Missing_Terminator_Recovery_Boundary.
- Added Parse_Generic_Formal_Declaration_Aspect_Or_Terminator to preserve generic-formal aspect placement and record formal-declaration-specific completion metadata.
- Extended token-cursor parsing for formal object, formal type, formal subprogram, and formal package declarations to use the new helper.
- Added AUnit regression Test_Language_Model_Token_Cursor_Generic_Formal_Declaration_Terminator_Pass817.
- Updated README, Ada parser coverage matrix, syntax-colouring notes, release checklist, and  validation guards.

This improves structural grammar coverage for Ada generic formal declaration completion. It is not compiler-grade generic contract conformance, formal declaration legality checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
