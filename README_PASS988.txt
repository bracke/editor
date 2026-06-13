Editor Phase 579 — Pass988

This pass adds one compiler-grade building block for Address clause legality inside the representation-legality layer. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as cross-unit semantic closure, full expression type inference, complete freezing interactions, private-view consumers, and deeper representation/operational attribute legality are fully integrated.

Implemented:
- Address clause target compatibility in Editor.Ada_Representation_Legality.
- Address value-shape classification for static address expressions, null literals, raw literals, arbitrary non-static names, and malformed values.
- Separate statuses for incompatible Address targets, null Address values, non-static Address names, incompatible raw literal values, and malformed values.
- Deterministic counters for Address target errors, Address value errors, and accepted static Address values.
- AUnit regression: Test_Ada_Address_Clause_Legality_Pass988.

Preserved invariants:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command-palette/keybinding/workspace/render mutation leaks.
- Deterministic, bounded, snapshot-owned analysis metadata.
