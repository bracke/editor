Editor pass795 — raise statement terminator recovery depth

Pass795 deepens Ada raise-statement parser metadata.

Changed:
- Added Production_Raise_Terminator.
- Added Production_Raise_Missing_Terminator_Recovery_Boundary.
- Bare raise statements such as `raise;` retain reraise metadata and now also retain raise-specific terminator metadata.
- Raise statements with exception names and optional `with` message expressions retain existing target/message metadata and now retain raise-specific terminator metadata.
- Malformed or in-progress raise statements that reach a body/select boundary without a visible semicolon emit bounded raise-specific missing-terminator recovery metadata.
- Added AUnit regression: Test_Language_Model_Token_Cursor_Raise_Terminator_Recovery_Pass795.
- Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage and bounded recovery for Ada raise statements. It is not compiler-grade exception legality checking, handler-placement checking, message-expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
