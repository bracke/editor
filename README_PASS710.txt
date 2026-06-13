# Editor Phase 579 - Pass710 case-statement choice grammar depth

Pass710 continues the IDE-grade Ada language-intelligence work by deepening
structural token-cursor coverage for case-statement alternatives. The pass is
parser-owned and snapshot-owned; it does not add rendering-side parsing, file
reloads, dirty-state mutation, LSP integration, compiler invocation, external
parser generators, Python project scripts, or shell project scripts.

Implemented grammar-depth changes:

* Added explicit case-statement choice-list markers for `when ... =>`
  alternatives.
* Added case-statement `others` choice markers that are distinct from exception
  handler `others` choices.
* Added explicit case choice separator markers for `|` inside case-statement
  alternatives.
* Added explicit case choice arrow markers for `=>` in case alternatives.
* Added bounded recovery markers for malformed case alternatives with missing
  arrows.
* Preserved existing generic `Production_Discrete_Choice_List`,
  `Production_Discrete_Choice`, and case-alternative statement-sequence markers
  for compatibility.

Regression coverage:

* Added `Test_Language_Model_Token_Cursor_Case_Statement_Choice_Depth_Grammar_Completeness`.
* The test covers multi-choice alternatives, range choices, `others` choices,
  explicit arrows, malformed missing-arrow alternatives, and continuation into
  following statements after recovery.

Validation and documentation:

* Updated `tools/phase579_language_validation_check.adb` with pass710 guards.
* Updated README, Outline documentation, syntax-colouring documentation, and the
  release checklist with the case-statement choice grammar-depth note.

This improves structural grammar coverage for Ada case-statement alternatives.
It is not compiler-grade legality checking for choice coverage, duplicate or
overlapping choices, staticness, selector typing, reachability, or full statement
control-flow semantics.
