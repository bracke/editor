Editor Phase 579 — Pass916

This pass improves structural Ada grammar recovery for malformed exit-when
conditions at reserved statement-sequence boundaries.

Implemented:
- Added Production_Exit_When_Reserved_Boundary_Recovery_Boundary.
- Refined exit-statement parsing so `exit when else;` and similar boundary
  forms do not fabricate the boundary keyword as a condition expression.
- Preserved existing exit-when missing-condition recovery, valid following
  condition metadata, exit terminators, and generic recovery metadata.
- Added AUnit regression coverage via
  Test_Language_Model_Token_Cursor_Exit_When_Reserved_Boundary_Recovery_Pass916.
- Updated validation guard comments, parser coverage docs, syntax-colouring
  notes, release checklist, and README.

This improves structural grammar coverage for malformed Ada exit-when
conditions. It is not Boolean condition legality checking, loop-name legality
checking, exit-statement legality checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.
