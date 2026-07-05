Pass1024 - private-with visibility constraints

This pass adds one compiler-grade building block for cross-unit Ada semantic
visibility.  Full compiler-grade Ada analysis remains incomplete until the
remaining layers such as overload resolution, type checking, generic contracts,
freezing/representation legality, and cross-unit semantic closure are fully
integrated.

Implemented:
- Added Editor.Ada_Private_With_Rules.
- Projects private with dependencies from cross-unit visibility into a
  lookup-facing private-with rule model.
- Distinguishes visible-part, package private-part, and package-body lookup
  contexts.
- Hides private-with dependencies from ordinary visible-part lookup.
- Exposes private-with dependencies in private-part and body lookup contexts.
- Preserves ordinary with/use dependencies as non-private dependencies visible
  in all unit contexts.
- Preserves missing/ambiguous/overflow dependencies as explicit diagnostic
  metadata.
- Added deterministic counters and fingerprints.
- Added AUnit regression:
  Test_Ada_Private_With_Visibility_Constraints_Pass1024.

Invariants:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command-palette/keybinding/workspace/render mutation leaks.
- Snapshot-owned deterministic metadata only.
