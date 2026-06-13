Editor Phase 579 pass1027

This pass adds one compiler-grade building block for cross-unit separate-body legality: body-stub matching and subunit placement metadata.

Implemented:
- Added Editor.Ada_Separate_Body_Stub_Rules.
- Projects existing cross-unit separate-body legality records into body-stub placement checks.
- Locates matching body stubs in the resolved parent body analysis without reparsing or file IO.
- Classifies matched stubs, missing stubs, ambiguous stubs, kind/profile mismatches, profile-unknown cases, parent-resolution failures, parent role mismatches, overflow, and missing separate-target names.
- Added deterministic lookup and counters for matched/missing/ambiguous stub checks and parent failures.
- Added AUnit regression Test_Ada_Separate_Body_Stub_Placement_Pass1027.

Full compiler-grade Ada analysis remains incomplete until the remaining semantic layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
