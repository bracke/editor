Editor — IDE-grade Outline / Semantic Colouring / Ada Parser
Pass898: entry-body statement-sequence recovery

This pass improves structural grammar coverage for Ada entry bodies whose body
begin is followed immediately by a recovery boundary rather than by a statement
sequence.

Code changes:
- Added Production_Entry_Body_Statement_Sequence.
- Added Production_Entry_Body_Missing_Statement_Recovery_Boundary.
- Refined entry body scanning so non-empty entry bodies expose statement-sequence
  metadata, while empty/boundary-only bodies expose entry-body-specific recovery.
- Preserved existing entry body begin/end metadata, generic recovery metadata,
  and valid following protected body structure.

Regression coverage:
- Added Test_Language_Model_Token_Cursor_Entry_Body_Statement_Recovery_Pass898.

Validation/docs updates:
- Updated tools/language_validation_check.adb.
- Updated docs/ada_parser_coverage_matrix.md.
- Updated docs/syntax_colouring.md.
- Updated docs/release/RELEASE_CHECKLIST.md.
- Updated README.md.

Scope statement:
This improves structural grammar coverage for malformed Ada entry-body statement
sequences. It is not compiler-grade tasking legality checking, entry barrier
legality checking, statement legality checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.
