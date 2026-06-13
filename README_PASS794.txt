Editor Phase 579 language-model pass794

Scope: return-statement terminator and extended-return missing-end recovery depth.

Changed:
- Added `Production_Return_Terminator`.
- Added `Production_Extended_Return_Missing_End_Recovery_Boundary`.
- Simple return statements with visible semicolons now retain return-specific terminator metadata.
- Extended return do-parts that do not expose `end return` before the surrounding body/select boundary now retain bounded missing-end recovery metadata.
- Preserved existing return-expression, extended-return object declaration, initializer, do-part, statement-sequence, end-return, and shared recovery productions.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Pass794`.
- Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage and bounded recovery for Ada return statements. It is not compiler-grade return-type conformance checking, accessibility checking, extended-return legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
