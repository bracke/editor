Editor — pass914
==========================

This pass improves Ada token-cursor structural grammar coverage for malformed
extended return object initializers.

Added production:

* Production_Extended_Return_Initializer_Reserved_Boundary_Recovery_Boundary

Parser/token-cursor updates:

* Extended return object initializers now detect reserved boundaries immediately
  after `:=`.
* The parser no longer fabricates `do`, `end`, `else`, `elsif`, `exception`,
  `then`, `when`, or `;` as initializer expressions in malformed extended
  return headers.
* Surrounding extended return metadata remains visible, including initializer,
  `do`, `end return`, generic recovery, and return recovery metadata.

Regression coverage added:

* Test_Language_Model_Token_Cursor_Extended_Return_Initializer_Reserved_Boundary_Recovery_Pass914

Updated:

* src/core/editor-ada_token_cursor.ads
* src/core/editor-ada_token_cursor.adb
* tests/src/editor-syntax_semantics-tests.adb
* tools/language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

This improves structural grammar coverage for malformed Ada extended return
object initializers at reserved boundaries.  It is not compiler-grade return
object legality checking, initializer type checking, definite-assignment
analysis, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state mutation.
