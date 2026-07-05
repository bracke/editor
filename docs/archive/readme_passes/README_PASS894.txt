Editor IDE-grade Outline / Semantic Colouring / Ada Parser
Pass894 - declare-expression missing-body recovery

Summary
=======

This pass improves structural Ada expression grammar coverage for malformed Ada
2022 declare expressions whose begin keyword is present but whose body expression
is missing.

Changes
=======

* Added Production_Declare_Expression_Missing_Body_Recovery_Boundary.
* Added At_Declare_Expression_Body_Boundary so delimiters, separators,
  semicolons, arrows, and reserved expression boundaries are not consumed as
  declare-expression body primaries during recovery.
* Refined declare-expression parsing to emit body-specific recovery metadata
  when begin is followed immediately by a boundary token.
* Preserved declare-expression metadata, begin-keyword metadata, generic
  recovery metadata, and following declaration visibility.
* Added AUnit regression
  Test_Language_Model_Token_Cursor_Declare_Expression_Body_Recovery_Pass894.
* Updated validation guard comments, parser coverage docs, syntax-colouring
  notes, release checklist, and README.

Scope
=====

This improves editor-owned structural grammar recovery for malformed declare
expressions. It is not expression type checking, declarative-part legality
checking, overload resolution, compiler invocation, LSP integration, render-side
parsing, background whole-project scanning, or dirty-state mutation.
