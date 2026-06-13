Editor Phase 579 — IDE-grade Outline / Semantic Colouring / Ada Parser — Pass874

This pass improves structural Ada grammar coverage for exception-handler statement-sequence recovery.

Changes:
* Added `Production_Exception_Handler_Missing_Statement_Recovery_Boundary`.
* Added `Production_Exception_Handler_End_Statement_Recovery_Boundary`.
* Exception handlers now distinguish `when X =>` recovery at a following `when`, `exception`, `end`, or semicolon from ordinary handler metadata.
* Terminal handlers that reach the enclosing `end` immediately after `=>` now receive a terminal-end recovery marker.
* Added AUnit regression `Test_Language_Model_Token_Cursor_Exception_Handler_Statement_Recovery_Pass874`.
* Updated validation guards, parser coverage docs, syntax-colouring notes, release checklist, and README.

This improves structural grammar coverage only. It is not compiler-grade exception-choice legality checking, handler ordering validation, statement legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
