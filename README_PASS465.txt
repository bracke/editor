Pass 465 - duplicate pragma named-argument legality

Focus:
- Extend the bounded legality layer from call association lists to executable
  pragma argument association lists.

Implemented:
- Added Legality_Duplicate_Pragma_Named_Argument.
- Retained every top-level named argument selector in executable pragmas such
  as Assert and Loop_Invariant instead of only the first leading argument name.
- Added a legality pass that diagnoses duplicate named pragma arguments inside
  the same pragma argument list, for example:
    pragma Assert (Check => Ready, Message => Image (State), Check => Valid);
- Kept the check syntactic/model-based; it does not attempt pragma-specific
  semantic validation beyond the existing executable-pragma filter.
- Added regression coverage:
    Test_Language_Model_Legality_Pragma_Named_Argument_Pass
