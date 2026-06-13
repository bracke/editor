Pass 520 - Multi-entity representation pragma lowering

Implemented another representation/operational property completeness pass.

Changes:
- Added multi-entity pragma lowering for Boolean entity pragmas that accept entity lists.
- `pragma Inline (G, H);` now lowers unified representation metadata for both `G` and `H`, not only the first listed entity.
- Applied the same multi-target path to common entity-list pragmas:
  - Inline
  - Inline_Always
  - No_Inline
  - No_Return
  - Unreferenced
  - Unmodified
  - Weak_External
  - Volatile
  - Atomic
  - Independent
  - Discard_Names
- Kept value-bearing pragmas on their existing single-target/value extraction paths:
  - Attach_Handler
  - Priority / CPU / Relative_Deadline / Max_Entry_Queue_Length
  - Linker_Section / Machine_Attribute
  - Suppress / Unsuppress
  - policy and restriction pragmas
- Extended regression coverage in the representation pragma unification test to prove both entities in `pragma Inline (G, H);` receive explicit `Representation_Inline_Clause` metadata.
