# Editor Phase 579 pass735 — validation guard cleanup

This pass continues the IDE-grade Outline / semantic-colouring Ada language-model work from pass734.

Implemented cleanup:

* Added typed guard helper routines to `tools/phase579_language_validation_check.adb` for recent parser/model checks:
  * language-model API markers
  * language-model body markers
  * parser projection markers
  * resolver-body markers
  * token-cursor production markers
  * syntax-regression markers
* Added `Check_Recent_Grammar_Pass_Guards`, a pass-ordered guard matrix covering pass724 through pass734.
* Grouped recent guard requirements by concrete grammar/model family:
  * object declaration internals
  * number declaration internals
  * formal package actual projection
  * use-clause projection
  * formal package resolver views
  * pragma placement metadata
  * aspect placement productions
  * representation/operational source-form projection
  * package declarative-item recovery
  * anonymous access-to-subprogram edge profiles
  * expression/name edge recovery
* Removed the duplicate invocation of `Check_Parser_And_Model_Features` from the validation tool main flow.
* Replaced terse end-of-file pass731-pass734 marker comments with a single maintainable pass724-pass734 guard note pointing at the grouped matrix.
* Updated README, Outline notes, semantic-colouring notes, and release checklist.

This improves validation guard maintainability for the recent Ada grammar-coverage passes. It does not add new Ada grammar recognition and does not claim compiler-grade legality checking.
