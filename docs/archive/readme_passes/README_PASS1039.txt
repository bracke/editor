Pass1039 - cross-unit diagnostics projection

This pass adds one compiler-grade building block for projecting cross-unit semantic closure and visibility metadata into stable diagnostics. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as deeper overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Implemented:
- Added Editor.Ada_Cross_Unit_Diagnostics.
- Projects cross-unit visibility, limited-with rules, private-with rules, body/spec conformance, child-unit visibility, and separate-body stub rules into deterministic diagnostics.
- Added diagnostic severity, kind, source/target unit metadata, stable source span defaults, and deterministic fingerprints.
- Added counters for error, warning, info, kind-specific counts, and model fingerprint.
- Added AUnit regression:
  - Test_Ada_Cross_Unit_Diagnostics_Projection_Pass1039

Safety/invariants:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command-palette/keybinding/workspace/render mutation leaks.
- Diagnostics consume already-built snapshot-owned semantic models.
