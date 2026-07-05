Pass1035 — Generic formal package nested actual conformance

Implemented:
- Added Editor.Ada_Generic_Formal_Package_Nested_Conformance.
- Compared formal package nested actuals against the actual package instance supplied to an enclosing generic instantiation.
- Classified boxed nested actual compatibility, exact nested actual compatibility, nested mismatches, missing nested actuals, wrong generic targets, unresolved actual package instances, and unknown/malformed cases.
- Added deterministic counters and fingerprints for diagnostics and semantic-colouring consumers.
- Added AUnit regression Test_Ada_Generic_Formal_Package_Nested_Conformance_Pass1035.

This pass adds one compiler-grade building block for generic formal package conformance. Full compiler-grade Ada analysis remains incomplete until generic renaming, nested generic instantiation visibility, formal object/default type compatibility, overload resolution, type checking, freezing/representation legality, and cross-unit semantic closure are fully integrated.
