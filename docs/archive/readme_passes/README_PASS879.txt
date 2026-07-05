Editor Pass879
========================

Pass879 improves structural Ada grammar coverage for anonymous
access-to-subprogram recovery.

Implemented:

* Added Production_Access_Protected_Missing_Subprogram_Recovery_Boundary.
* Added Production_Access_Function_Missing_Return_Recovery_Boundary.
* Added Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary.
* Refined token-cursor access-definition parsing so malformed forms such as
  `access protected`, `access function (...)`, and `access function (...) return;`
  retain specific recovery metadata.
* Added AUnit regression coverage in
  Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refined_Recovery_Pass879.
* Updated validation guards, parser coverage docs, syntax-colouring docs,
  release checklist, and README.

This improves structural grammar coverage only. It is not compiler-grade
callable-profile legality checking, result subtype legality checking, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.
