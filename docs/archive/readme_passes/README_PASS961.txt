Editor Semantic language-model pass961

Implemented next compiler-grade semantic pass after pass960.

Changes:
- Extended Editor.Ada_Static_Expressions with scalar subtype-bound metadata.
- Added Static_Type_Bound_Info records and deterministic type-bound fingerprints.
- Added bounded static attribute handling for T'First, T'Last, T'Pos (...), and T'Val (...).
- Preserved unsupported attributes as explicit Static_Value_Unsupported_Attribute metadata.
- Added AUnit regression Test_Ada_Static_Attribute_Expression_Foundation_Pass961.
- Updated parser coverage, syntax-colouring notes, validation guards, release checklist, and README.

Scope:
This is a compiler-grade static-expression building block. Full Ada static-expression legality still requires complete real/universal arithmetic, enumeration literal positions, static string/character operations, modular overflow rules, static attribute completeness, generic contracts, freezing/representation legality, and cross-unit semantic closure.
