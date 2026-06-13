### Pass816 - Number declaration terminator recovery depth

Pass816 deepens Ada named-number declaration completion metadata. Number declarations now retain `Production_Number_Declaration_Terminator` when their visible semicolon is present and `Production_Number_Declaration_Missing_Terminator_Recovery_Boundary` when a declaration reaches the next synchronization token without its own terminator. Existing defining-name-list, grouped-name separator, constant keyword, initializer expression, and initializer recovery metadata remains intact.

Changed:
- Added number-declaration-specific terminator metadata.
- Added bounded missing-terminator recovery metadata for malformed/in-progress named-number declarations.
- Added parser helper `Parse_Number_Declaration_Aspect_Or_Terminator` so named-number completion no longer relies on the generic aspect/semicolon helper.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Number_Declaration_Terminator_Pass816`.
- Updated README, coverage matrix, syntax-colouring notes, release checklist, and phase579 validation guards.

This improves structural grammar coverage for Ada named-number declaration completion. It is not compiler-grade static-expression evaluation, named-number legality, universal integer/real resolution, aspect legality checking, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

