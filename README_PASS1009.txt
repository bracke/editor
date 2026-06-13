Editor Phase 579 pass1009

This pass adds one compiler-grade building block for Ada expression type inference: indexed component and slice result inference.

Implemented:
- Extended Editor.Ada_Expression_Types with Indexed_Slice_Inference_Status.
- Indexed component nodes now retain prefix subtype, index subtype, result element subtype, index count, compatible index count, mismatch count, unknown count, and deterministic fingerprint metadata.
- Slice nodes now retain prefix subtype, index subtype, and array/slice result subtype metadata.
- Added counters for resolved prefixes, compatible/mismatched/unknown index checks, element results, and array slice results.
- Added AUnit regression Test_Ada_Expression_Indexed_Slice_Inference_Pass1009.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as deeper array type constraints, container indexing aspects, overload-selected indexing functions, cross-unit type closure, and diagnostic surfacing are fully integrated.
