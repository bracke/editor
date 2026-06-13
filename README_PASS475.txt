Pass 475 - Address representation value legality

Focus
- Continue the representation/operational legality track after pass 474.
- Add bounded Address clause value checking without requiring full System.Address type inference.

Implemented
- Added legality diagnostic kinds:
  - Legality_Address_Value_Required
  - Legality_Address_Value_Incompatible
- Address representation clauses now diagnose empty address expressions.
- Address representation clauses now diagnose obvious non-address literal values such as raw numeric, Boolean, and string literals.
- Address-shaped expressions such as System'To_Address (...) and X'Address are accepted for later resolver/type checking.
- Added regression coverage:
  - Test_Language_Model_Legality_Address_Representation_Value_Pass

Notes
- This remains a bounded IDE legality layer. Full System.Address compatibility, overload resolution for To_Address, and elaboration/freezing checks remain later semantic work.
