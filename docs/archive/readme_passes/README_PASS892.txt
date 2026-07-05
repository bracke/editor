Editor Pass892
==========================

This pass implements the next bounded expression-grammar recovery slice after
pass891: Ada 2022 reduction attribute argument recovery.

Changed files:

* src/core/editor-ada_token_cursor.ads
* src/core/editor-ada_token_cursor.adb
* tests/src/editor-syntax_semantics-tests.adb
* tools/language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

Implemented:

* Added Production_Reduction_Missing_Reducer_Recovery_Boundary.
* Added Production_Reduction_Missing_Initial_Value_Recovery_Boundary.
* Added Production_Reduction_Trailing_Separator_Recovery_Boundary.
* Refined reduction attribute argument parsing for malformed Reduce,
  Parallel_Reduce, and Map_Reduce forms such as missing reducer slots, trailing
  separators after the reducer, and missing close delimiters.
* Preserved existing reduction-expression, parallel-reduction, map-reduction,
  attribute-argument delimiter, missing-close, generic recovery, and following
  declaration metadata.
* Added AUnit regression
  Test_Language_Model_Token_Cursor_Reduction_Argument_Recovery_Pass892.

This improves structural grammar coverage for malformed Ada reduction attribute
argument parts. It is not callable profile checking, initial-value type
compatibility checking, parallel-reduction legality checking, overload
resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.
