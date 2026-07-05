# Editor pass737 — case-statement alternative depth grammar

Pass737 improves structural token-cursor coverage for Ada case-statement
alternatives.  The parser now retains explicit metadata for the `is` boundary,
individual case choices, range choices, choice separators already present in
case alternatives, `others` choices, and null-statement alternatives.

Added productions:

* `Production_Case_Statement_Is_Keyword`
* `Production_Case_Choice`
* `Production_Case_Range_Choice`
* `Production_Case_Alternative_Null_Statement`

Added regression:

* `Test_Language_Model_Token_Cursor_Case_Statement_Alternative_Depth`

This improves structural grammar coverage for case-statement alternatives used
by Outline, syntax-tree recovery, and semantic-colouring consumers.  It is not
compiler-grade discrete-choice legality checking, coverage/exhaustiveness
checking, static-expression validation, or control-flow analysis.
