Editor — Pass910

This pass improves structural Ada grammar recovery for malformed if/elsif statement conditions.

Changes:
- Added Production_If_Statement_Missing_Condition_Recovery_Boundary.
- Added Production_Elsif_Statement_Missing_Condition_Recovery_Boundary.
- Refined if-statement parsing so `if then` records missing-condition recovery instead of treating `then` as a condition expression.
- Refined elsif-part parsing so `elsif then` records missing-condition recovery instead of treating `then` as a condition expression.
- Preserved then-keyword metadata, valid following condition metadata, end-if terminator metadata, generic recovery metadata, and following declaration/statement visibility.
- Added AUnit regression Test_Language_Model_Token_Cursor_If_Elsif_Condition_Recovery_Pass910.
- Updated validation guard comments, parser coverage matrix, syntax-colouring notes, release checklist, and README.

Scope:
This improves structural grammar coverage for malformed Ada if/elsif statement conditions. It is not Boolean condition legality checking, expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
