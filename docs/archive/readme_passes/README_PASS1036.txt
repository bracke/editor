Pass1036 — Generic renaming and nested generic instantiation visibility

Implemented:
- Added Editor.Ada_Generic_Renaming_Visibility.
- Staged generic renaming declarations as deterministic lookup-facing metadata, including renamed target, resolved target declaration, target formal region, candidate count, and source span.
- Classified renamed generic targets as resolved, unresolved, ambiguous, non-generic, malformed, or unknown.
- Staged generic instantiations that target renamed generics and nested generic instantiations inside generic/body/block regions.
- Resolved instantiations through generic renamings back to the original generic declaration and formal region where available.
- Preserved direct generic instantiation metadata separately from renamed generic instantiation metadata.
- Added deterministic counters and fingerprints for diagnostics and semantic-colouring consumers.
- Added AUnit regression Test_Ada_Generic_Renaming_Nested_Visibility_Pass1036.

This pass adds one compiler-grade building block for generic renaming and nested generic instantiation visibility. Full compiler-grade Ada analysis remains incomplete until generic actual default-expression type compatibility, generic body semantic use of formal package actuals, overload resolution, type checking, freezing/representation legality, and cross-unit semantic closure are fully integrated.
