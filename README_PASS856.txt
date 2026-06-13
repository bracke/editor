Editor Phase 579 Pass856 — Return statement missing-terminator recovery depth

This pass improves structural grammar coverage for Ada return statement completion.

Implemented:
- Added Production_Return_Missing_Terminator_Recovery_Boundary.
- Updated simple return-statement parsing so malformed/in-progress return statements without a semicolon record return-specific bounded recovery metadata.
- Preserved existing return statement, return expression, return terminator, extended-return, and broader return recovery metadata.
- Added AUnit coverage in Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Pass856.
- Updated validation guard and documentation.

Scope:
- Parser/token-cursor structural metadata only.
- No compiler-grade return legality checking.
- No return type conformance validation.
- No overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
