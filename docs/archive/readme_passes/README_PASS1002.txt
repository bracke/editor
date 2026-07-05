Pass1002 — expression operator operand/result inference

This pass adds one compiler-grade building block for Ada expression type inference.
It extends Editor.Ada_Expression_Types with deterministic operator metadata so
operator-shaped expressions preserve operand subtype shape, normalized operator
symbol, result subtype shape, operand mismatch counts, operand unknown counts,
and operator-resolution status.

Implemented scope:

- Added Operator_Type_Inference_Status.
- Added operator symbol/result/operand metadata to Expression_Type_Info.
- Added deterministic fingerprints that include operator metadata.
- Added predefined operator inference for:
  - numeric +, -, *, /, mod, rem, **
  - Boolean and/or/xor/not and short-circuit operators
  - relational and membership-shaped Boolean results
- Added operand classification for literal children, visible simple-name children,
  and call-shaped operands when call-resolution metadata is available.
- Added counters:
  - Operator_Resolved_Count
  - Operator_Operand_Mismatch_Count
  - Operator_Operand_Unknown_Count
  - Operator_Ambiguous_Count
- Added AUnit regression:
  - Test_Ada_Expression_Operator_Operand_Inference_Pass1002

This pass is still conservative. It does not claim complete Ada overload
resolution for all user-defined operators. It provides queryable operand/result
metadata for the later overload-aware and expected-type-aware expression passes.

Full compiler-grade Ada analysis remains incomplete until user-defined operator
overload resolution, aggregate component inference, conversion legality,
attribute result typing, private-view-aware expression typing, and cross-unit
semantic visibility are fully integrated.
