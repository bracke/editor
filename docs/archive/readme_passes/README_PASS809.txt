Editor Pass809

Scope: entry body end/recovery depth.

Changes:
- Added Production_Entry_Body_Begin_Keyword.
- Added Production_Entry_Body_End_Keyword.
- Added Production_Entry_Body_End_Name.
- Added Production_Entry_Body_End_Terminator.
- Added Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary.
- Entry body scans now retain begin/end/end-name/terminator metadata for protected entry bodies.
- Entry bodies with a visible begin part but no matching entry-body end before a surrounding boundary now retain bounded entry-body-specific recovery metadata.
- Added Test_Language_Model_Token_Cursor_Entry_Body_End_Recovery_Pass809.
- Updated validation guards, parser coverage notes, and release checklist.

This improves structural grammar coverage and bounded recovery for Ada entry body endings. It is not compiler-grade tasking legality checking, entry/body conformance checking, protected-operation conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
