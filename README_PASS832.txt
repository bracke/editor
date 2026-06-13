# Pass832 - Discrete choice-list separator and recovery depth

Pass832 improves structural grammar coverage for Ada discrete choice lists used by case alternatives, variant parts, and related choice-list contexts.

Changed:
- Added token-cursor productions for discrete-choice separators and missing-choice recovery:
  - `Production_Discrete_Choice_Separator`
  - `Production_Discrete_Choice_Missing_Choice_Recovery_Boundary`
- Updated `Parse_Discrete_Choice_List` so `|` separators are retained as structural metadata.
- Added bounded recovery for malformed/in-progress choice lists such as `when A | =>`, leaving the following `=>` available to the enclosing alternative parser.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators_Pass832`.
- Updated validation guards, parser coverage documentation, syntax-colouring notes, and the release checklist.

This improves structural grammar coverage for Ada discrete choice-list separators and malformed choice recovery. It is not compiler-grade discrete-choice legality checking, duplicate-choice validation, range static evaluation, variant legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
