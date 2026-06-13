Pass820 - Pragma argument delimiter and recovery depth

Pass820 deepens Ada pragma argument-list metadata. Argument-bearing pragmas now retain explicit argument-list open/close delimiter productions, comma separator productions between pragma argument associations, and a bounded missing-close recovery production when an in-progress pragma argument list reaches a semicolon before its closing parenthesis. Existing pragma identifier, nullary pragma, named/positional argument association, argument identifier, argument expression, box, representation-pragma, and operational-pragma metadata remains intact.

Changed:
- Added `Production_Pragma_Argument_List_Open_Delimiter`.
- Added `Production_Pragma_Argument_List_Close_Delimiter`.
- Added `Production_Pragma_Argument_Association_Separator`.
- Added `Production_Pragma_Argument_List_Missing_Close_Recovery_Boundary`.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Pragma_Argument_Delimiters_Pass820`.
- Updated parser coverage docs, syntax-colouring notes, release checklist, and validation guards.

This improves structural grammar coverage for Ada pragma argument-list delimiters, separators, and missing-close recovery. It is not compiler-grade pragma legality checking, aspect/pragma semantic equivalence, implementation-defined pragma validation, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
