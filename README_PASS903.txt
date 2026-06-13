Editor Phase 579 - Pass903
==========================

Pass903 improves structural grammar coverage for malformed Ada delay statements at reserved statement-sequence boundaries.

Changes:

* Added Production_Delay_Reserved_Boundary_Recovery_Boundary.
* Refined delay and delay-until parsing so reserved boundaries such as then, when, terminate, and abort are not treated as delay expressions.
* Preserved existing delay statement, missing-expression, terminator, and generic recovery metadata.
* Added Test_Language_Model_Token_Cursor_Delay_Expression_Reserved_Boundary_Recovery_Pass903.
* Updated validation guard comments, parser coverage notes, syntax-colouring notes, release checklist, and README.

This improves editor-owned structural grammar recovery only. It is not compiler-grade delay-expression legality checking, tasking legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
