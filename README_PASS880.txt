Editor Phase 579 Pass880
========================

Pass880 improves structural Ada grammar coverage for conditional-expression
operand recovery.

Implemented parser/token-cursor metadata:

* Production_If_Expression_Missing_Condition_Recovery_Boundary
* Production_If_Expression_Missing_Then_Branch_Recovery_Boundary
* Production_If_Expression_Missing_Else_Branch_Recovery_Boundary

The pass covers malformed forms such as:

* (if then 1 else 2)
* (if Ready then else 2)
* (if Ready then 1 else)

The parser preserves conditional-expression metadata, generic recovery metadata,
and following declaration visibility.

Regression coverage added:

* Test_Language_Model_Token_Cursor_Conditional_Expression_Recovery_Pass880

Updated validation/release guards and documentation:

* tools/phase579_language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

This is structural grammar coverage only. It is not expression type checking,
Boolean legality checking, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or dirty
state mutation.
