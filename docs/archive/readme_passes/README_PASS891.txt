Editor Pass891
==========================

This pass implements resolver/semantic-colouring follow-through for recovered
partial parser metadata.

Changed files:

* src/core/editor-syntax_semantics.adb
* tests/src/editor-syntax_semantics-tests.adb
* tools/language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

Implemented:

* Added conservative suppression of recovered partial metadata names before they
  seed the bounded semantic-colouring map.
* Suppressed unresolved executable bindings whose expression text indicates a
  recovered incomplete selected qualification or allocator subtype mark.
* Suppressed metadata-only visibility names ending in a dangling selected-name
  separator.
* Preserved concrete symbol-derived colouring for resolved bindings.
* Added AUnit regression
  Test_Syntax_Semantics_Recovered_Metadata_Suppressed_Pass891.

This improves semantic-colouring false-positive suppression for recovered
partial names. It is not compiler-grade name binding, overload resolution,
compiler invocation, LSP integration, render-side parsing, background
whole-project scanning, or dirty-state mutation.
