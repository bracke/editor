Pass1055 — cross-unit selected-name expression inference

This pass adds one compiler-grade building block for routing cross-unit selected-name resolution into expression/type inference.

Implemented:
- Extended Editor.Ada_Expression_Types with cross-unit selected-name expression statuses.
- Added Build_With_Cross_Unit_Selected_Names and Build_With_Cross_Unit_Selected_Names_And_Expected entry points.
- Preserved selected-name identity, selected-name status, target unit, target path, selector text, normalized target/selector text, candidate count, source span, and deterministic fingerprint.
- Classified cross-unit selected names as resolved, limited-view, private-view, or unresolved/missing/ambiguous/overflow.
- Counted cross-unit selected-name totals and resolved/limited/private/unresolved subsets.
- Routed unresolved limited/private/cross-unit failures into expression diagnostics as unresolved expression cases.
- Added Test_Ada_Expression_Cross_Unit_Selected_Name_Inference_Pass1055.

Invariant notes:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command-palette/keybinding/workspace/render mutation leaks.
- Cross-unit expression metadata remains deterministic, bounded, and snapshot-owned.
