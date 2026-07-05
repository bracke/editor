Pass1065 - Selected-name representation target diagnostics projection

Implemented:
- Extended Editor.Ada_Representation_Diagnostics with Build_With_Selected_Targets.
- Consumes Editor.Ada_Selected_Representation_Targets.
- Projects selected representation target failures into representation/freezing diagnostics.
- Adds diagnostic kinds for limited/private view barriers, missing/ambiguous/overflow prefixes, missing/ambiguous selectors, and unresolved selected targets.
- Preserves target text, selector text, source span, severity, message payload, source fingerprint, and deterministic fingerprints.
- Adds selected-target diagnostic counters and AUnit regression coverage in Test_Ada_Representation_Diagnostics_Selected_Targets_Pass1065.

Invariant notes:
- The new path is projection-only.
- No rendering-side parsing, file IO, dirty-state mutation, command registration, workspace mutation, or renderer semantic work is introduced.
- The original representation diagnostics Build path is preserved unchanged.

This pass adds one compiler-grade building block for selected-name-aware representation diagnostics. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
