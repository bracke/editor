Editor — Pass923

This pass improves structural grammar coverage for malformed Ada parameter/profile default expressions at reserved or delimiter boundaries.

Changes:
- Added Production_Profile_Default_Reserved_Boundary_Recovery_Boundary.
- Refined profile default parsing so := followed by ), ;, ,, =>, with, is, then, else, elsif, or, when, exception, end, or EOF is recorded as profile-default-specific recovery instead of being parsed as an ordinary default expression.
- Preserved parameter-profile metadata, default-expression metadata, declaration terminator metadata, and generic recovery metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Profile_Default_Reserved_Boundary_Recovery_Pass923.
- Updated validation guard notes, parser coverage docs, syntax-colouring docs, release checklist, and README.

This is structural grammar recovery for editor services only. It is not compiler-grade default-expression legality checking, profile conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
