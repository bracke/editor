Editor — Pass 1032

This pass adds one compiler-grade building block for operational attribute duplicate/conflict checking. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Implemented:
- Added Editor.Ada_Operational_Attribute_Rules.
- Consumes the unified representation-legality stream after aspect/attribute-definition normalization.
- Stages operational properties such as Pack, Atomic, Volatile, Independent, component operational attributes, Suppress_Initialization, Unchecked_Union, Discard_Names, Volatile_Full_Access, and Atomic_Always_Lock_Free.
- Classifies duplicate operational properties on one normalized target.
- Classifies contradictory Boolean operational values on one normalized target/property.
- Preserves target/value errors from the representation-legality layer.
- Exposes deterministic counters and fingerprints for diagnostics and future semantic-colouring projection.
- Added AUnit regression Test_Ada_Operational_Attribute_Duplicate_Conflict_Pass1032.

Invariant preservation:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command-palette/keybinding/workspace/render mutation leaks.
- Analysis remains deterministic, bounded, and snapshot-owned.
