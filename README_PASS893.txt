Editor Phase 579 - IDE-grade Outline / Semantic Colouring / Ada Parser
Pass893 - quantified-expression missing-predicate recovery

This pass continues from pass892 and adds a bounded Ada expression grammar
recovery refinement.

Implemented:

* Added Production_Quantified_Missing_Predicate_Recovery_Boundary.
* Refined quantified-expression parsing so malformed forms with a present
  quantified arrow but no predicate expression expose quantified-specific
  recovery metadata.
* Covered malformed forms such as:

     (for all I in 1 .. 3 =>)
     (for some I in 1 .. 3 =>, True)
     (for all I in 1 .. 3 => when others => True)

* Preserved quantified-expression metadata, quantified-arrow metadata, generic
  recovery metadata, and following declaration visibility.
* Added AUnit regression:

     Test_Language_Model_Token_Cursor_Quantified_Predicate_Recovery_Pass893

Updated:

* src/core/editor-ada_token_cursor.ads
* src/core/editor-ada_token_cursor.adb
* tests/src/editor-syntax_semantics-tests.adb
* tools/phase579_language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

This improves structural grammar coverage for malformed Ada quantified
expression predicates. It is not Boolean predicate legality checking, iterator
legality checking, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state mutation.
