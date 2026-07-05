Pass865 - Extended return missing-do recovery depth

Changes:
- Added `Production_Extended_Return_Missing_Do_Recovery_Boundary`.
- Updated extended return parsing so malformed/in-progress return-object forms that reach a semicolon before `do` retain extended-return-specific missing-do recovery metadata.
- Preserved `Production_Return_Recovery_Boundary` for existing broader recovery consumers.
- Added `Test_Language_Model_Token_Cursor_Extended_Return_Do_Recovery_Pass865`.
- Updated parser coverage, syntax-colouring notes, release checklist, and validation guard metadata.

This improves structural grammar coverage for Ada extended return statement completion. It is not compiler-grade return-object legality checking, subtype conformance validation, expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
