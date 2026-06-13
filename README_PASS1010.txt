Pass1010 implements dereference and access-designator expression inference.

This pass adds one compiler-grade building block for Ada expression type analysis. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Changes:
- Extended Editor.Ada_Expression_Types with dereference/access inference metadata.
- Added Dereference_Access_Inference_Status for explicit dereference expressions and Access-family attributes.
- Explicit dereferences such as P.all now retain prefix subtype, designated subtype, resolved/error/unknown status, and deterministic fingerprint contribution.
- Access, Unchecked_Access, and Unrestricted_Access attributes now retain target subtype and inferred access result subtype where the target can be resolved through direct visibility.
- Added deterministic counters:
  - Dereference_Resolved_Count
  - Dereference_Target_Error_Count
  - Dereference_Unknown_Count
  - Access_Result_Resolved_Count
  - Access_Result_Unknown_Count
- Added AUnit regression Test_Ada_Expression_Dereference_Access_Inference_Pass1010.
- Updated README, parser coverage matrix, syntax-colouring notes, release checklist, and strict runtime validation notes.
