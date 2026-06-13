Pass 543 - static numeric operator kind refinement

Implemented another precise static-evaluation pass for representation legality.

Changes:
- The numeric-only static recognizer used by properties such as Small now carries a bounded universal numeric kind.
- Universal-real operands no longer satisfy integer-only operators mod/rem.
- Universal-real arithmetic over retained static real constants is still accepted for Small.
- Universal-integer mod/rem remains accepted for numeric-only clauses.
- Added Test_Language_Model_Representation_Static_Numeric_Type_Kind_Pass.

Validation:
- The pass updates source and AUnit coverage in the project archive.
