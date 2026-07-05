Editor pass793 - delay statement terminator recovery depth

Pass793 deepens Ada delay-statement recovery metadata.

Changes:
- Added `Production_Delay_Missing_Terminator_Recovery_Boundary`.
- Preserved existing delay-specific terminator metadata via `Production_Delay_Statement_Terminator`.
- Delay-until statements such as `delay until Clock.Now;` continue to retain mode-specific expression and terminator metadata.
- Relative delay statements such as `delay 1.0` that reach a body/select boundary without a visible semicolon now retain bounded missing-terminator recovery metadata.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Delay_Terminator_Recovery_Pass793`.
- Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage and bounded recovery for Ada delay statements. It is not compiler-grade delay-expression legality checking, real-time semantics, select-alternative legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
