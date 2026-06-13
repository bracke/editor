Editor Phase 579 IDE-grade Outline/Semantic Language Model - Pass 430

This pass extends Ada token-cursor grammar coverage for incomplete type declarations.

Implemented:
- Added Production_Incomplete_Type_Declaration.
- Added Production_Tagged_Incomplete_Type_Declaration.
- Plain incomplete type declarations such as `type Node;` are now retained as explicit grammar nodes instead of only generic type declarations followed by opaque semicolon recovery.
- Discriminated incomplete declarations such as `type Cursor (Kind : Natural);` preserve their discriminant part and still retain incomplete-type metadata.
- Tagged incomplete declarations such as `type Root is tagged;` are no longer routed through full type-definition recovery as a lone `tagged` modifier.
- Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Incomplete_Type_Grammar_Completeness.
- Updated validation guards, release guard comments, README, outline docs, syntax-colouring docs, and release checklist.

Still intentionally out of scope:
- Compiler-grade incomplete-type completion legality.
- Full/private view matching.
- Freezing, accessibility, and representation legality.
- GNAT-equivalent semantic validation.
