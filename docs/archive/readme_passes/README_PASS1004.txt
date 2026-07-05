# Editor — Pass1004

Pass1004 adds conversion and qualified-expression inference to `Editor.Ada_Expression_Types`.

## Implemented

- Added `Conversion_Type_Inference_Status`.
- Added conversion-target and operand-subtype metadata to `Expression_Type_Info`.
- Added deterministic conversion counters for resolved targets, compatible operands, explicit-conversion operands, mismatches, and unknown/malformed cases.
- Qualified expressions now reuse the conversion metadata path for target-subtype resolution and operand compatibility.
- Function-call-shaped type conversions are distinguished from ordinary unresolved calls when the designator resolves as a type.
- Conversion metadata contributes to expression-type fingerprints.
- Added AUnit regression coverage:
  - `Test_Ada_Expression_Conversion_Qualified_Inference_Pass1004`

This pass adds one compiler-grade building block for expression type inference. Full compiler-grade Ada analysis remains incomplete until user-defined conversion interactions, overload-aware call/conversion disambiguation, attribute result typing, private-view-aware expression typing, and cross-unit semantic visibility are fully integrated.
