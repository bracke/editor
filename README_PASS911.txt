Editor Phase 579 — Pass911

This pass improves structural Ada grammar recovery for malformed while-loop statement conditions.

Changes:
- Added Production_While_Loop_Missing_Condition_Recovery_Boundary.
- Refined while-loop parsing so `while loop` records missing-condition recovery instead of treating `loop` as a condition expression.
- Reserved statement-sequence boundaries after `while` are treated as recovery boundaries, not fabricated condition expressions.
- Preserved while-keyword metadata, loop-keyword metadata, valid following condition metadata, loop terminator metadata, generic recovery metadata, and following declaration/statement visibility.
- Added AUnit regression Test_Language_Model_Token_Cursor_While_Condition_Recovery_Pass911.
- Updated validation guard comments, parser coverage matrix, syntax-colouring notes, release checklist, and README.

Scope:
This improves structural grammar coverage for malformed Ada while-loop conditions. It is not Boolean condition legality checking, expression type checking, loop-statement legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
