Editor Pass966

This pass adds the first generic contract model foundation for compiler-grade Ada analysis.

Changed:
- Added `Editor.Ada_Generic_Contracts`.
- Records generic formal type, object, subprogram, and package declarations from direct visibility metadata.
- Preserves formal default/default-box markers where structurally available.
- Records generic instantiation actual shape: positional count, named count, total count, named actual names, and target generic name.
- Added AUnit regression `Test_Ada_Generic_Contract_Foundation_Pass966`.
- Updated parser coverage, syntax-colouring notes, release checklist, validation record, and README.

Scope:
This is a compiler-grade generic-analysis building block. Full formal/actual conformance, generic body contract visibility, overload matching, type checking, private-view legality, static-expression legality, freezing/representation legality, and cross-unit semantic closure remain future work.
