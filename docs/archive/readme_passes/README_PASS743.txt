# Editor pass743 — aggregate association depth metadata

Pass743 deepens structural Ada aggregate association metadata in the token cursor.
The parser now retains explicit markers for individual aggregate index/component
choices, range choices, box component values, and extension-aggregate component
associations while preserving existing positional, named, `others`, null-record,
extension, and delta aggregate coverage.

Regression coverage:

* `Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness`

Validation guard coverage now requires the new pass743 token-cursor markers:

* `Production_Aggregate_Index_Choice`
* `Production_Aggregate_Range_Choice`
* `Production_Aggregate_Box_Component`
* `Production_Extension_Aggregate_Component_Association`

This improves structural grammar coverage for Ada aggregate associations used by
Outline, semantic colouring, and recovery. It is not compiler-grade aggregate
completeness checking, index constraint checking, named-component legality,
duplicate-choice legality, expected-type resolution, or static-expression
validation.
