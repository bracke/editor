Editor IDE-grade Outline / Semantic Colouring / Ada Parser - Pass 673

Focus: object declaration internal grammar.

Changes:
- Added token-cursor productions for object declaration internals:
  - Production_Object_Defining_Name_List
  - Production_Object_Subtype_Indication
  - Production_Object_Initialization_Expression
- Updated object declaration parsing so the defining-name-list position, subtype/access side, and initializer expression side are retained explicitly.
- Preserved existing object qualifier, subtype-indication, access-definition, aspect, and recovery paths.
- Added AUnit regression coverage for aliased/constant object declarations, access object declarations, selected operator subtype marks, initializer expressions, attached aspects, and recovery through following declarations.
- Updated README.md and docs/release/RELEASE_CHECKLIST.md.

Scope:
This improves structural grammar coverage for Ada object declaration internals. It is not compiler-grade legality checking for assignability, subtype compatibility, initialization legality, constant object rules, or visibility.
