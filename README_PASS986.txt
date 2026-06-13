Editor Phase 579 pass986

This pass adds one compiler-grade building block for record representation clause completeness.

Implemented:
- Extended Editor.Ada_Representation_Legality with Record_Component_Legality_Info.
- Stages every Node_Representation_Component_Clause under record representation clauses.
- Resolves component clauses against the represented record type's component declarations.
- Evaluates component storage-unit, first-bit, and last-bit expressions through Editor.Ada_Static_Expressions.
- Classifies valid component clauses, unresolved components, duplicate components, non-static component positions, negative positions, reversed bit ranges, and incompatible non-record targets.
- Added deterministic component counters:
  - Record_Component_Check_Count
  - Record_Component_Error_Count
  - Record_Component_Duplicate_Count
  - Record_Component_Static_Error_Count
- Added AUnit regression:
  - Test_Ada_Record_Representation_Component_Legality_Pass986

This pass adds a compiler-grade representation-legality building block. Full compiler-grade Ada analysis remains incomplete until remaining layers such as cross-unit semantic closure, full expression type inference, complete representation/operational legality, and diagnostic integration are fully integrated.
