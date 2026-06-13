Editor Phase 579 — IDE-grade Outline / Semantic Colouring / Ada Parser — Pass905

This pass improves structural Ada grammar recovery for malformed return statements whose return-expression position is occupied by a reserved statement-sequence boundary.

Changes:
- Adds Production_Return_Reserved_Boundary_Recovery_Boundary.
- Refines simple return-statement parsing so forms such as `return else;` do not fabricate `else`, `or`, `end`, `exception`, `then`, or `when` as ordinary return expressions.
- Preserves broader return recovery metadata, valid following return-expression metadata, return terminator metadata, and generic recovery points.
- Adds AUnit coverage:
  Test_Language_Model_Token_Cursor_Return_Expression_Reserved_Boundary_Recovery_Pass905.

This is editor-grade structural grammar recovery only. It is not compiler-grade return legality checking, function/procedure conformance checking, expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
