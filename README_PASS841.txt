Editor Phase 579 - Pass841
==========================

Pass841 improves Ada if-expression grammar recovery in the token cursor.

Implemented
-----------

* Added Production_If_Expression_Missing_Then_Recovery_Boundary.
* Added Production_Elsif_Expression_Missing_Then_Recovery_Boundary.
* Updated if-expression parsing so malformed or in-progress forms such as
  `(if Ready else False)` retain bounded missing-then recovery metadata.
* Updated elsif-expression parsing so malformed or in-progress forms such as
  `(if Ready then True elsif Enabled else False)` retain bounded missing-then
  recovery metadata.
* Preserved existing condition, branch-expression, else-expression, and
  missing-else recovery metadata.
* Added AUnit regression coverage in
  Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery_Pass841.
* Updated README, parser coverage notes, syntax-colouring notes, release
  checklist, and validation guard markers.

Scope
-----

This improves structural grammar coverage for Ada if-expression and
elsif-expression missing-then recovery. It is not compiler-grade conditional
expression legality checking, branch type checking, overload resolution,
compiler invocation, LSP integration, render-side parsing, or dirty-state
mutation.
