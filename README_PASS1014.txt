Pass1014 — operator overload resolution using operand expression types

This pass adds one compiler-grade building block for Ada expression type analysis by extending Editor.Ada_Expression_Types with overload-aware operator inference metadata.

Implemented:

* Added optional Build_With_Operator_Uses and Build_With_Operator_Uses_And_Expected entry points that accept Editor.Ada_Use_Type_Operators.Primitive_Use_Model.
* Added operator-overload statuses for resolved, ambiguous, mismatch, and unknown operator-overload cases.
* Operator-shaped expressions can now combine operand subtype shapes with primitive operators exposed by use type / use all type.
* Added deterministic metadata for overload candidate counts, selected overload counts, ambiguity counts, and mismatch counts.
* Operator-overload metadata contributes to expression fingerprints.
* Added deterministic counters:
  * Operator_Overload_Resolved_Count
  * Operator_Overload_Ambiguous_Count
  * Operator_Overload_Mismatch_Count
  * Operator_Overload_Unknown_Count
* Added AUnit regression:
  * Test_Ada_Expression_Operator_Overload_Resolution_Pass1014

This remains snapshot-owned semantic analysis. It performs no rendering-side parsing, file IO, compiler invocation, dirty-state mutation, or command/workspace/render mutation.

Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
