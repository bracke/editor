Editor Phase 579 Pass881 — Selected literal name refinement

Pass881 improves structural Ada token-cursor name grammar for selected names
whose selectors are operator-symbol string literals or character literals.

Changes:
- Literal selected-name selectors now also emit Production_Selected_Selector,
  keeping them visible through the same generic selector path used for ordinary
  identifier selectors.
- Added qualified-expression selected literal subtype-mark metadata:
  Production_Qualified_Expression_Selected_Literal_Subtype_Mark,
  Production_Qualified_Expression_Selected_Operator_Subtype_Mark, and
  Production_Qualified_Expression_Selected_Character_Subtype_Mark.
- Added allocator selected literal subtype-mark metadata:
  Production_Allocator_Selected_Literal_Subtype_Mark,
  Production_Allocator_Selected_Operator_Subtype_Mark, and
  Production_Allocator_Selected_Character_Subtype_Mark.
- Added AUnit coverage in
  Test_Language_Model_Token_Cursor_Selected_Literal_Name_Refinement_Pass881.
- Updated validation guards, parser coverage docs, syntax-colouring notes,
  release checklist, and README.

This is structural grammar coverage only. It is not subtype legality checking,
operator legality checking, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or
analysis-side dirty-state mutation.
