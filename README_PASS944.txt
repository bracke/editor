Editor Phase 579 pass944

Compiler-grade direct-visibility foundation pass.

Implemented:
- Added Editor.Ada_Direct_Visibility.
- Extracted declarations from parser-owned Ada syntax-tree declaration nodes.
- Assigned declarations to directly enclosing declarative regions from Editor.Ada_Declarative_Regions.
- Recorded stable declaration IDs, declaration kinds, source nodes, source ranges, normalized Ada names, and deterministic fingerprints.
- Added direct region lookup and enclosing-region lookup.
- Added AUnit regression Test_Ada_Direct_Visibility_Foundation_Pass944.
- Updated parser coverage notes, syntax-colouring notes, release checklist, strict runtime validation notes, and README.

Scope:
This pass adds a compiler-grade semantic building block for direct visibility. Full compiler-grade Ada analysis remains incomplete until use-clause visibility, overload resolution, expected-type propagation, type checking, static evaluation, generic contracts, freezing/representation legality, and cross-unit semantic closure are integrated.
