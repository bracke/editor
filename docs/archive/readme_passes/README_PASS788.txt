### Pass788 - accept statement end/recovery depth

- Added `Production_Accept_End_Keyword`, `Production_Accept_End_Name`, `Production_Accept_Terminator`, and `Production_Accept_Missing_End_Recovery_Boundary`.
- Accept statements with `do` parts now retain accept-specific end metadata for forms such as `accept Start (...) do ... end Start;`.
- Malformed or in-progress accept do-parts that reach a select/statement boundary before an accept end now emit accept-specific missing-end recovery metadata.
- Added `Test_Language_Model_Token_Cursor_Accept_End_Recovery_Pass788` and updated validation/release guards.
- This improves structural grammar coverage and bounded recovery for Ada accept statements. It is not compiler-grade tasking legality checking, accept-body conformance checking, entry-call matching, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

