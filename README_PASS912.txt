Editor Phase 579 — Pass912

This pass improves structural Ada grammar recovery for malformed for-loop and iterator-loop domains at reserved statement-sequence boundaries.

Added productions:

* Production_For_Loop_Domain_Reserved_Boundary_Recovery_Boundary
* Production_Iterator_Loop_Domain_Reserved_Boundary_Recovery_Boundary

The token cursor now avoids treating reserved boundary tokens such as else, or, then, when, exception, end, delimiters, and separators as ordinary iteration domains in forms such as:

   for I in else loop
   for C of else loop

The broader missing-domain recovery metadata is preserved, and valid following discrete and iterator domains remain visible after recovery.

Regression coverage added:

* Test_Language_Model_Token_Cursor_For_Iterator_Domain_Reserved_Boundary_Recovery_Pass912

This improves structural grammar coverage only. It is not compiler-grade discrete range legality checking, iterator legality checking, expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
