# Editor Phase 579 - Pass709 range/index constraint grammar depth

Pass709 continues the IDE-grade Ada language-intelligence work by deepening
structural token-cursor coverage for range constraints, index constraints, and
range attributes used in constraint contexts.  The pass is parser-owned and
snapshot-owned; it does not add rendering-side parsing, file reloads,
dirty-state mutation, LSP integration, compiler invocation, external parser
generators, Python project scripts, or shell project scripts.

Implemented grammar-depth changes:

* Added explicit range lower-bound and upper-bound productions so subtype,
  index, membership, and aggregate-adjacent range consumers can retain bound
  positions without re-tokenizing expressions.
* Added range-attribute reference/prefix productions for forms such as
  `Natural'Range` used as a range constraint.
* Added explicit per-item index-constraint markers for multi-dimensional
  constraints.
* Added bounded constraint recovery markers for malformed ranges and trailing
  index-constraint commas.
* Preserved existing `Production_Range_Constraint`, `Production_Range_Expression`,
  attribute-reference, subtype-indication, and array-index-subtype markers for
  compatibility.

Regression coverage:

* Added `Test_Language_Model_Token_Cursor_Range_Constraint_Depth_Grammar_Completeness`.
* The test covers scalar range constraints, range-attribute constraints,
  multi-dimensional index constraints, malformed upper bounds, trailing index
  commas, and continuation into following declarations.

Validation and documentation:

* Updated `tools/phase579_language_validation_check.adb` with pass709 guards.
* Updated README, Outline documentation, syntax-colouring documentation, and the
  release checklist with the range/index constraint grammar-depth note.

This improves structural grammar coverage for Ada range and index constraints.
It is not compiler-grade legality checking for discrete subtype legality,
staticness, bound ordering, index subtype compatibility, dimension matching,
attribute availability, or constraint conformance.
