Editor Phase 579 pass962

Pass962 extends the compiler-grade static-expression staging layer with enumeration literal position metadata.

Changed:
- Extended Editor.Ada_Static_Expressions with Static_Enumeration_Literal_Info records.
- Staged enumeration literals declared under enumeration type declarations with deterministic zero-based positions and fingerprints.
- Added lookup by enumeration literal name and by position.
- Resolved enumeration T'Pos (Literal) operands to static integer positions when the literal is known.
- Resolved enumeration T'Val (Position) operands to enumeration-literal metadata when the position is known.
- Preserved unresolved enumeration Pos operands as unresolved-name metadata for later diagnostics.
- Added AUnit regression Test_Ada_Static_Enumeration_Position_Foundation_Pass962.
- Updated parser coverage, syntax-colouring notes, release checklist, README, and this pass note.

Scope:
This is a compiler-grade static-expression building block. It does not yet complete full Ada static-expression legality, complete discrete-type legality, character/string static handling, real/universal arithmetic, modular overflow rules, generic contracts, freezing/representation legality, compiler invocation, LSP integration, renderer-side parsing, background scanning, file mutation, or dirty-state mutation.
