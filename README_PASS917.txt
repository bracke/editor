Editor Phase 579 — IDE-grade Outline / Semantic Colouring / Ada Parser — Pass917

This pass improves structural grammar recovery for malformed Ada null statements at reserved statement-sequence boundaries.

Changes:
- Added Production_Null_Reserved_Boundary_Recovery_Boundary.
- Refined null-statement parsing so forms such as `null else` expose null-statement-specific reserved-boundary recovery metadata instead of only generic missing-terminator recovery.
- Preserved Production_Null_Statement, Production_Null_Missing_Terminator_Recovery_Boundary, valid following Production_Null_Statement_Terminator metadata, and generic Production_Recovery_Point metadata.
- Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Null_Reserved_Boundary_Recovery_Pass917.
- Updated the validation guard, parser coverage matrix, syntax-colouring notes, release checklist, and root README.

This improves structural grammar coverage for malformed Ada null statements at reserved statement-sequence boundaries. It is not compiler-grade statement legality checking, control-flow validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
