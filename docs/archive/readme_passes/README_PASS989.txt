Pass989 — Size, Alignment, and Storage_Size legality

This pass extends Editor.Ada_Representation_Legality with a focused compiler-grade representation-legality layer for Size, Object_Size, Value_Size, Alignment, Component_Size, Storage_Size, Machine_Radix, and Aft style integer-valued representation clauses.

Implemented:
- Target-kind checks for Size-family clauses.
- Target-kind checks for Alignment clauses.
- Access-type-oriented target checks for Storage_Size clauses.
- Integer-valued static-expression enforcement for integer representation values.
- Separate real-valued static expression rejection through Representation_Legality_Static_Value_Not_Integer.
- Existing positive-value checks now remain distinct from integer-shape checks.
- Deterministic counters for Size/Alignment/Storage target-shape errors and static-value errors.
- AUnit regression: Test_Ada_Size_Alignment_Storage_Legality_Pass989.

This pass adds one compiler-grade building block for representation clause legality. Full compiler-grade Ada analysis remains incomplete until remaining operational attributes, private-view-aware representation checks, cross-unit semantic closure, freezing interactions, and full expression type inference are fully integrated.
