# Editor pass804 — If / elsif missing-then recovery depth

This pass deepens Ada if-statement recovery metadata while preserving the existing bounded token-cursor architecture.

Implemented changes:

* Added `Production_If_Statement_Missing_Then_Recovery_Boundary`.
* Added `Production_Elsif_Statement_Missing_Then_Recovery_Boundary`.
* If statements that retain a condition but omit `then` now emit if-specific missing-then recovery metadata before the existing shared if-statement recovery marker.
* Elsif branches that retain a condition but omit `then` now emit elsif-specific missing-then recovery metadata before the existing shared if-statement recovery marker.
* Existing well-formed if/elsif condition, then-keyword, then-statement, else-branch, end-keyword, and end-terminator metadata remain intact.
* Added AUnit regression `Test_Language_Model_Token_Cursor_If_Missing_Then_Recovery_Pass804`.
* Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage and bounded recovery for Ada if and elsif statement branches. It is not compiler-grade condition legality checking, expected Boolean type analysis, control-flow analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
