Editor Phase 579 pass952

Implemented compiler-grade call-resolution result classification.

Changes:
- Added `Editor.Ada_Call_Resolution`.
- Built deterministic resolution records from call candidates plus profile filters.
- Classified missing call names, unresolved call designators, pre-profile ambiguity, missing filter data, no viable profiles, unique profile matches, and ambiguous viable profile sets.
- Added AUnit regression `Test_Ada_Call_Resolution_Profile_Result_Pass952`.
- Updated parser coverage, syntax-colouring notes, release checklist, strict runtime validation notes, and README.

Scope:
This is a compiler-grade overload-resolution staging layer. It does not yet complete expected-type propagation, full profile conformance, type checking, implicit conversion legality, generic contract matching, freezing/representation legality, or cross-unit semantic closure.
