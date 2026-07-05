Editor pass918
========================

This pass improves structural grammar recovery for malformed Ada aggregate named component associations where a reserved statement-sequence or expression boundary appears where the component expression is expected.

New production metadata:

* Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary

Covered malformed form:

   Broken : Arr := (1 => else, 2 => 10);

The parser now records aggregate-component-specific reserved-boundary recovery instead of treating the boundary keyword as a component expression. Existing aggregate arrow metadata, aggregate recovery metadata, generic recovery metadata, and following valid associations remain visible.

Regression coverage:

* Test_Language_Model_Token_Cursor_Aggregate_Component_Reserved_Boundary_Recovery_Pass918

Updated files:

* src/core/editor-ada_token_cursor.ads
* src/core/editor-ada_token_cursor.adb
* tests/src/editor-syntax_semantics-tests.adb
* tools/language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

This improves structural grammar coverage for malformed Ada aggregate component expressions. It is not compiler-grade aggregate legality checking, component type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
