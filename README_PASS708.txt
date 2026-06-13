# Editor Phase 579 - Pass708 aggregate association grammar depth

Pass708 continues the IDE-grade Ada language-intelligence work by deepening
structural token-cursor coverage for aggregate association forms.  The pass is
parser-owned and snapshot-owned; it does not add rendering-side parsing, file
reloads, dirty-state mutation, LSP integration, compiler invocation, external
parser generators, Python project scripts, or shell project scripts.

Implemented grammar-depth changes:

* Added aggregate-specific token-cursor productions for positional aggregate
  components, named component associations, component choice lists, association
  arrows, `others` choices, `null record` extension aggregates, and bounded
  aggregate recovery boundaries.
* Retained existing generic `Production_Component_Association` markers for
  compatibility while making aggregate-specific shape visible to downstream
  Outline, semantic-colouring, and regression consumers.
* Improved malformed aggregate handling for missing expressions after `=>` so
  the parser exposes a bounded recovery boundary and continues into following
  declarations.
* Preserved existing delta aggregate, extension aggregate, iterated component
  association, and ordinary expression parsing behavior.

Regression coverage:

* Added `Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness`.
* The test covers positional aggregates, named associations, choice lists,
  `others =>`, `null record` extension aggregates, malformed association
  recovery, and continuation into following declarations.

Validation and documentation:

* Updated `tools/phase579_language_validation_check.adb` with pass708 guards.
* Updated README, Outline documentation, syntax-colouring documentation, and the
  release checklist with the aggregate association grammar-depth note.

This improves structural grammar coverage for Ada aggregate association forms.
It is not compiler-grade legality checking for aggregate typing, component
coverage, discriminant-dependent components, record/array aggregate legality,
choice staticness, duplicate choices, accessibility, overload resolution, or
expected-type resolution.
