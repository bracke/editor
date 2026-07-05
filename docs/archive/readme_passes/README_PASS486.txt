Pass 486 - Representation pragma unification

Implemented another representation/aspect completeness pass on top of pass 485.

Changes:
- Lowered representation pragmas into the same bounded representation-clause metadata model used by aspects and attribute-definition clauses.
- Added common lowering for:
  - pragma Pack (Entity)
  - pragma Atomic (Entity)
  - pragma Volatile (Entity)
  - pragma Independent (Entity)
  - pragma Suppress_Initialization (Entity)
- Representation pragmas now participate in the existing duplicate-representation detection path.
- Representation pragmas now reuse the existing target/value legality checks for Pack, Atomic, Volatile, Independent, and Suppress_Initialization.
- Added regression coverage proving pragma Pack and for T'Pack use ... collide through the shared model, and that pragma-based Atomic/Volatile/Suppress_Initialization metadata is retained.

Intent:
This completes the next source-form unification layer after aspect-vs-attribute-definition unification: representation-relevant pragmas are no longer isolated pragma metadata where the editor legality model cannot reason about them.
