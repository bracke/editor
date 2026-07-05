Editor pass786 - exception handler missing-arrow recovery depth

Implemented a bounded Ada parser/token-cursor grammar recovery pass for malformed exception handlers.

Changes:
- Added Production_Exception_Handler_Missing_Arrow_Recovery_Boundary.
- Exception handlers whose choices are retained but whose => arrow is omitted now produce handler-specific recovery metadata.
- Existing exception handler, choice-list, named-choice, selected-choice, others-choice, separator, arrow, statement-sequence, and shared recovery productions remain intact.
- Added Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Arrow_Pass786.
- Updated validation guards, parser coverage notes, release checklist, and README.

Scope:
This improves structural grammar recovery for Ada exception handlers. It is not compiler-grade exception-handler legality checking, exception choice resolution, duplicate-choice analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
