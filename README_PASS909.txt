Editor Phase 579 - IDE-grade Outline / Semantic Colouring / Ada Parser - Pass909

This pass improves bounded structural grammar recovery for malformed Ada call actual association lists.

Changes:
- Added Production_Call_Actual_Missing_Actual_Recovery_Boundary.
- Added Production_Call_Actual_Trailing_Separator_Recovery_Boundary.
- Added Production_Call_Actual_Empty_List_Recovery_Boundary.
- Added corresponding entry-call actual recovery productions.
- Refined call/entry-call actual-list scanning so empty lists, missing named actual expressions, and trailing separators expose call-specific recovery metadata.
- Added Test_Language_Model_Token_Cursor_Call_Actual_Association_Recovery_Pass909.
- Updated validation guards, parser coverage notes, syntax-colouring notes, release checklist, and README.

This improves structural grammar coverage for malformed Ada call actual association lists. It is not callable profile checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
