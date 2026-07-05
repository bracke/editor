Editor Pass1003 — expression aggregate context inference

This pass adds one compiler-grade building block for Ada expression type inference: aggregate and container-aggregate context inference.

Implemented scope:

* Extended Editor.Ada_Expression_Types with Aggregate_Type_Inference_Status metadata.
* Aggregate expressions now retain expected-context-derived subtype shape instead of remaining only aggregate_context_required.
* Added aggregate component metadata:
  - aggregate element subtype shape
  - aggregate index subtype shape
  - component count
  - named association count
  - positional association count
  - mismatch count
  - unknown/context-required count
* Added recognition for array-style positional aggregates, record-style named aggregates, delta aggregates, and Ada 2022 container aggregates.
* Aggregates without an expected subtype remain explicitly context-required instead of being accepted silently.
* Aggregate metadata participates in deterministic expression-type fingerprints.
* Added counters:
  - Aggregate_Context_Required_Count
  - Aggregate_Context_Resolved_Count
  - Aggregate_Mismatch_Count
  - Aggregate_Unknown_Count
* Added AUnit regression:
  - Test_Ada_Expression_Aggregate_Context_Inference_Pass1003

This pass improves the expression type model by making aggregate inference context-sensitive while preserving deterministic bounded analysis and graceful unknown/mismatch states. Full compiler-grade Ada analysis remains incomplete until remaining expression inference, overload resolution, generic contracts, private-view visibility, freezing/representation legality, and cross-unit semantic closure are fully integrated.
