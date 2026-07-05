# Editor Pass1011

Pass1011 adds allocator expression type inference as the next compiler-grade expression-analysis building block.

Implemented scope:

- Extended `Editor.Ada_Expression_Types` with allocator-specific inference metadata.
- Added allocator target subtype extraction for `new T` and qualified allocator shapes such as `new T'(...)`.
- Added expected-access-context propagation for allocator expressions in declaration-default contexts.
- Resolves expected named access types through `Editor.Ada_Type_Graph` and derives their designated subtype where the type graph exposes access-type metadata.
- Records allocator target subtype, expected access subtype, designated subtype, inferred result subtype, normalized forms, status, and deterministic fingerprint contribution.
- Classifies allocator targets and results as resolved, malformed/unresolved, expected-non-access, designated-compatible, designated-mismatched, or result-known without context.
- Added deterministic counters:
  - `Allocator_Resolved_Count`
  - `Allocator_Target_Error_Count`
  - `Allocator_Designated_Resolved_Count`
  - `Allocator_Unknown_Count`
- Added AUnit regression:
  - `Test_Ada_Expression_Allocator_Inference_Pass1011`

This pass adds one compiler-grade building block for allocator expression typing. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
