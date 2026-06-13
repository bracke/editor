Pass 313 — Structured declaration metadata nodes

This pass converts Ada declaration metadata that was previously retained mostly as symbol flags or string slices into first-class parser-owned syntax-tree nodes.

Implemented:
- Added syntax-tree node kinds for pragma arguments, aspect specifications/associations, representation clauses/targets/items, and generic actual parts/associations.
- Parsed pragma argument lists structurally for both context pragmas and pragma statements.
- Parsed aspect specifications on declaration lines and aspect-continuation lines inside scopes.
- Parsed representation clauses such as `for T use ...` and retained target/item metadata plus named aggregate associations where present.
- Parsed one-line generic instantiation actual parts into generic actual association nodes with formal/actual child metadata.
- Added AUnit coverage for aspects, pragmas, representation clauses, and generic actuals.
- Extended the Phase 579 validation gate so these nodes and tests cannot be silently removed.

The implementation remains deterministic, snapshot-owned, and UI/rendering independent.
