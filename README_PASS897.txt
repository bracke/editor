Editor Phase 579 - Pass897

This pass improves structural Ada grammar coverage for malformed renaming tails.

Changes:
- Added Production_Renaming_Missing_Renames_Recovery_Boundary.
- Added Production_Renaming_Missing_Target_Recovery_Boundary.
- Refined Parse_Renaming_Tail so `renames ;` and `renames with ...` are treated
  as missing renamed-entity recovery instead of allowing `with` to be consumed
  as a renamed target.
- Preserved renaming declaration metadata, renaming aspect placement metadata,
  valid following renamed package targets, generic recovery metadata, and
  following declarations.
- Added Test_Language_Model_Token_Cursor_Renaming_Target_Recovery_Pass897.
- Updated validation guard comments, coverage docs, syntax-colouring notes,
  release checklist, and README.

Scope note:
This improves structural grammar coverage for malformed Ada renaming tails.  It
is not compiler-grade renamed-entity legality checking, visibility checking,
overload resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.
