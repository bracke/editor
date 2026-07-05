Editor Pass831 parenthesized-expression delimiter and recovery depth

Pass831 improves structural grammar coverage for Ada parenthesized expressions in the token cursor.

Changes:
- Added `Production_Parenthesized_Expression_Open_Delimiter`.
- Added `Production_Parenthesized_Expression_Close_Delimiter`.
- Added `Production_Parenthesized_Expression_Missing_Close_Recovery_Boundary`.
- Updated parenthesized-expression parsing so ordinary expressions, nested parenthesized expressions, and parenthesized conditional expressions retain parenthesized-expression-specific delimiter metadata.
- Added bounded missing-close recovery for malformed/in-progress parenthesized expressions without consuming the following declaration terminator.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters_Pass831`.
- Updated validation guards, parser coverage documentation, syntax-colouring notes, and the release checklist.

This improves structural grammar coverage for Ada parenthesized expressions. It is not compiler-grade expression legality checking, aggregate-vs-parenthesized semantic disambiguation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
