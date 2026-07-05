# Editor pass738 — select-statement alternative depth grammar

This pass deepens structural token-cursor coverage for Ada select-statement
alternatives while preserving the existing parser/model architecture.

## Implemented

* Added explicit token-cursor productions for select alternative metadata:
  * `Production_Select_First_Alternative`
  * `Production_Select_Accept_Alternative`
  * `Production_Select_Delay_Until_Alternative`
  * `Production_Select_Delay_Relative_Alternative`
  * `Production_Select_Terminate_Alternative`
  * `Production_Select_Guard_Arrow`
  * `Production_Select_Alternative_Null_Statement`
  * `Production_Select_Alternative_Recovery_Boundary`
* Select statements now retain the first alternative separately from later
  `or` alternatives.
* Accept alternatives inside select statements are now marked explicitly.
* Delay alternatives distinguish `delay until ...;` from relative `delay ...;`.
* Terminate alternatives retain a select-specific marker in addition to the
  general terminate alternative marker.
* Guard arrows after `when Condition =>` are retained, with a bounded recovery
  marker when the arrow is missing.
* Null statements inside select alternatives receive select-alternative recovery
  metadata.

## Regression coverage

Added AUnit regression:

* `Test_Language_Model_Token_Cursor_Select_Statement_Alternative_Depth`

The regression covers guarded accept alternatives, `or` alternatives,
`delay until`, relative delay, terminate alternatives, conditional `else`,
asynchronous `then abort`, select-alternative null statements, and recovery into
following declarations.

## Guards and docs

Updated:

* `tools/language_validation_check.adb`
* `README.md`
* `docs/ada_parser_coverage_matrix.md`
* `docs/outline.md`
* `docs/syntax_colouring.md`
* `docs/release/RELEASE_CHECKLIST.md`

## Non-goals

This improves structural grammar coverage for Ada select-statement alternatives.
It is not compiler-grade tasking legality checking, entry-call profile checking,
select-alternative legality checking, guard semantic validation, or control-flow
analysis.
