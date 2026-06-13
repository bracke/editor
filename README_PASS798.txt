# Editor Phase 579 — Pass798

Pass798 deepens Ada null-statement terminator recovery metadata.

## Changes

- Added `Production_Null_Missing_Terminator_Recovery_Boundary`.
- Well-formed null statements continue to retain `Production_Null_Statement_Terminator` for visible semicolons.
- Malformed or in-progress null statements that reach a body/select boundary without a visible semicolon now emit bounded null-specific recovery metadata.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Null_Terminator_Recovery_Pass798`.
- Updated validation/release guards and parser coverage documentation.

## Scope

This improves structural grammar coverage and bounded recovery for Ada null statements. It is not compiler-grade statement legality checking, reachability analysis, control-flow analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
