Editor Phase 579 — Pass926

This pass improves structural Ada grammar recovery for malformed record component declarations where a component default expression is missing and a reserved/aspect boundary follows the `:=` token.

Implemented:
- Added Production_Component_Default_Reserved_Boundary_Recovery_Boundary.
- Refined component declaration parsing so forms such as:
    Missing_With : Integer := with Volatile;
    Missing_Then : Integer := then;
  do not fabricate boundary tokens as component default expressions.
- Preserved component declaration metadata, generic recovery metadata, and valid following component default-expression metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Component_Default_Reserved_Boundary_Recovery_Pass926.
- Updated validation guard comments, parser coverage docs, syntax-colouring docs, release checklist, and README.

This improves structural grammar coverage for malformed Ada component default expressions at reserved/aspect boundaries. It is not compiler-grade component declaration legality checking, default-expression type checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
