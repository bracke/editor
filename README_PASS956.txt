Editor Phase 579 pass956

Compiler-grade semantic/type-system increment:
- Added `Editor.Ada_Type_Graph`.
- Builds stable semantic type nodes for type, subtype, and formal type declarations.
- Classifies range, modular, floating, fixed, array, record, access, private, derived, subtype, and formal type shapes.
- Resolves derived/subtype parent declarations through direct visibility and records unresolved/ambiguous bases for diagnostics.
- Adds ancestry/compatibility queries for exact, subtype-of, and derived-from declaration relationships.
- Added AUnit regression `Test_Ada_Type_Graph_Foundation_Pass956`.

This is a compiler-grade type-system building block. Full compiler-grade Ada analysis still requires private-view completion, class-wide/interface compatibility, implicit conversions, static expression evaluation, generic contracts, freezing/representation legality, and cross-unit semantic closure.
