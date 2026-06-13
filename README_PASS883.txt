Editor Phase 579 — Pass883
==========================

Pass883 improves structural Ada grammar coverage for accept-statement body
statement-sequence recovery.

Implemented:

- Added Production_Accept_Body_Missing_Statement_Recovery_Boundary.
- Added Production_Accept_Body_End_Statement_Recovery_Boundary.
- Extended accept-statement do-part parsing so empty or malformed accept bodies
  record accept-specific missing-statement recovery metadata.
- Distinguished accept bodies that recover directly on the accept end keyword.
- Preserved existing accept statement-sequence metadata, accept end metadata,
  malformed terminator metadata, select alternative visibility, and following
  declaration visibility.
- Added AUnit regression:
  Test_Language_Model_Token_Cursor_Accept_Body_Statement_Recovery_Pass883.
- Updated validation guards, parser coverage docs, syntax-colouring notes,
  release checklist, and README.

This improves structural grammar coverage for Ada accept-statement body recovery.
It is not compiler-grade tasking legality checking, accept-body legality checking,
entry-family validation, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or dirty
state mutation.
