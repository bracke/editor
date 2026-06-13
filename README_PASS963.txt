Editor Phase 579 pass963

Implemented compiler-grade static-expression modular integer foundation.

Changes:
- Extended Editor.Ada_Static_Expressions with modular type metadata.
- Added Static_Modular_Type_Info records containing type name, owning region, modulus text, evaluated static modulus value, source range, and fingerprint.
- Added lookup APIs for modular type metadata.
- Added Reduce_Modular_Integer for deterministic reduction of static integer expressions by a known modular type modulus.
- Preserved unresolved modular type names and malformed/non-static modulus cases as explicit metadata for later diagnostics.
- Added AUnit regression Test_Ada_Static_Modular_Integer_Foundation_Pass963.
- Updated parser coverage docs, syntax-colouring notes, release checklist, strict runtime validation record, and README.

Scope:
This pass is a compiler-grade static-expression building block. It does not complete Ada modular arithmetic legality, full discrete-type legality, universal/real arithmetic, generic contracts, freezing/representation legality, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
