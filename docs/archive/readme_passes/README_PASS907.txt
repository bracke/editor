Editor Pass907
==========================

Implemented another bounded Ada parser/token-cursor grammar recovery pass.

Summary
-------

- Added Production_Exit_Target_Reserved_Boundary_Recovery_Boundary.
- Refined malformed exit-statement target recovery where reserved statement-sequence boundaries appear where a loop name would otherwise be parsed.
- Added AUnit regression Test_Language_Model_Token_Cursor_Exit_Target_Reserved_Boundary_Recovery_Pass907.
- Updated validation guard comments, coverage docs, syntax-colouring docs, release checklist, and README.

Covered shape
-------------

   exit else;
   exit Worker when Done;

The first form now records exit-target reserved-boundary recovery metadata instead of fabricating `else` as an exit loop name. The second form verifies that valid following exit loop names, when conditions, and terminators remain structurally visible.

Non-goals
---------

This improves structural grammar coverage for malformed Ada exit targets at reserved statement-sequence boundaries. It is not compiler-grade loop-name legality checking, exit-statement legality checking, expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
