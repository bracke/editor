Editor Phase 579 - IDE-grade Outline / Semantic Colouring / Ada Parser - Pass902

Summary
=======

Pass902 improves structural Ada grammar recovery for malformed requeue statements
where a reserved statement-sequence boundary appears where an entry-name target is
required.

Changes
=======

* Added Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary.
* Refined requeue statement parsing so forms such as `requeue else;` do not
  fabricate the reserved boundary token as a requeue entry-name target.
* Preserved Production_Requeue_Missing_Target_Recovery_Boundary,
  Production_Requeue_Target_Recovery_Boundary, generic recovery metadata, and
  valid following requeue target/terminator metadata.
* Added Test_Language_Model_Token_Cursor_Requeue_Target_Reserved_Boundary_Recovery_Pass902.
* Updated validation guard comments, parser coverage documentation, syntax
  colouring notes, release checklist, and README.

Scope
=====

This improves structural grammar coverage for malformed Ada requeue targets at
reserved statement-sequence boundaries. It is not compiler-grade entry-name
legality checking, tasking legality checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.
