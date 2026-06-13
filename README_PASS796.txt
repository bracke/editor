Editor Phase 579 pass796 - exit statement terminator recovery depth

Implemented bounded Ada token-cursor coverage for exit statement terminators and missing-semicolon recovery.

Changes:
- Added Production_Exit_Terminator.
- Added Production_Exit_Missing_Terminator_Recovery_Boundary.
- Well-formed exit statements now retain exit-specific semicolon metadata.
- Malformed or in-progress exit statements that reach a body/select boundary without a visible semicolon now emit bounded recovery metadata.
- Added Test_Language_Model_Token_Cursor_Exit_Terminator_Recovery_Pass796.
- Updated validation guards, parser coverage notes, release checklist, and README.

This improves structural grammar coverage and bounded recovery for Ada exit statements. It is not compiler-grade loop-name resolution, condition legality checking, control-flow legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
