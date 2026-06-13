Editor Phase 579 pass785 - record representation recovery depth

This pass deepens bounded recovery for Ada record representation clauses.

Changes:
- Added `Production_Representation_Component_Missing_At_Recovery_Boundary`.
- Added `Production_Representation_Component_Missing_Range_Recovery_Boundary`.
- Added `Production_Record_Representation_Missing_End_Record_Recovery_Boundary`.
- Record representation component clauses are retained when either their `at` arm or their `range` arm is visible, instead of requiring both before the clause can be recognized structurally.
- Bare `end;` and missing `end record` inside a record representation clause now leave record-representation-specific recovery metadata.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Record_Representation_Recovery_Pass785`.
- Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage and hostile-source recovery for Ada record representation clauses. It is not compiler-grade representation legality checking, component layout validation, static-expression validation, target resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
