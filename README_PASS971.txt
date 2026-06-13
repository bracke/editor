Editor Phase 579 pass971

This pass adds one compiler-grade building block for generic body contract visibility.

Implemented:

- Extended Editor.Ada_Generic_Contracts with Generic_Body_Contract_Visibility_Info.
- Added deterministic mapping from a generic declaration's formal region to the matching package/subprogram body region.
- Records body contract visibility status, formal count, visible formal count, shadowed formal count, body node, body region, and fingerprints.
- Added Body_Contract_Visibility_Count, Body_Contract_Visibility_At, Body_Contract_Visibility_For_Body, Body_Formal_Visible, and Body_Formal APIs.
- Generic body regions can now query their generic formal type/object/subprogram/package contract declarations through the generic-contract model.
- Body-not-found and missing-formal-region states are preserved explicitly instead of being collapsed into absence.
- Added AUnit regression Test_Ada_Generic_Body_Contract_Visibility_Pass971.

Still incomplete before full compiler-grade Ada analysis:

- Overload-aware subprogram actual selection.
- Default-expression legality for generic actuals/defaulted formals.
- Private-view visibility rules.
- Freezing-point tracking.
- Representation-clause legality using static expressions and freezing state.
- Cross-unit semantic closure for specs, bodies, child units, and separate bodies.
- Full expression type inference and expected-type propagation beyond call results.
- Complete profile conformance, including modes and convention-sensitive rules.
