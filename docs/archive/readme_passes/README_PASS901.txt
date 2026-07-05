Editor Pass901

Scope
-----
This pass improves structural Ada grammar recovery for malformed abort
statement target lists where a comma is followed by a reserved
statement-sequence boundary.

Parser/token-cursor changes
---------------------------
* Added Production_Abort_Target_Reserved_Boundary_Recovery_Boundary.
* Refined abort statement target-list recovery so forms such as:

      abort Worker, else;

  do not fabricate the reserved boundary token as a task-name target.
* Preserved abort-statement, abort-target-list, abort-target-name,
  abort-terminator, abort recovery, generic recovery, and following statement
  visibility metadata.

Regression coverage
-------------------
* Added Test_Language_Model_Token_Cursor_Abort_Target_Reserved_Boundary_Recovery_Pass901.

Documentation / release guard updates
-------------------------------------
* Updated README, syntax-colouring notes, parser coverage matrix, release
  checklist, and  validation guard comments.

Limits
------
This improves structural grammar coverage for malformed Ada abort target
lists. It is not compiler-grade task-name legality checking, tasking legality
checking, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state
mutation.
