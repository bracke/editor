Editor pass990

Implemented Convention, Import, Export, External_Name, and Link_Name legality in Editor.Ada_Representation_Legality.

Highlights:
- Added interfacing value metadata for known convention identifiers, unknown convention identifiers, static Boolean Import/Export values, static string external/link names, malformed values, and unknown cases.
- Added target-shape legality for interfacing representation clauses.
- Added conflict detection for enabled Import and Export on the same target.
- Added standalone External_Name/Link_Name detection when the target has no enabled Import or Export clause.
- Added deterministic counters for interfacing errors, target errors, value errors, import/export conflicts, and link-name dependency errors.
- Added AUnit regression Test_Ada_Interfacing_Representation_Legality_Pass990.

This pass adds one compiler-grade building block for operational/interfacing representation legality. Full compiler-grade Ada analysis remains incomplete until remaining operational attributes, private-view-aware representation checks, cross-unit semantic closure, deeper freezing interactions, and full expression type inference are fully integrated.
