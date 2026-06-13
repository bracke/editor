Editor Phase 579 - Pass 674

Focus: number and exception declaration internal grammar.

Changes:
- Added dedicated token-cursor productions for named-number declaration internals:
  * Production_Number_Defining_Name_List
  * Production_Number_Initialization_Expression
- Added a dedicated token-cursor production for exception declaration internals:
  * Production_Exception_Defining_Name_List
- Updated identifier-led declaration parsing so grouped defining-name lists before ':' remain structural for object, number, and exception declarations.
- Number declarations now retain their defining-name-list position and initializer expression position explicitly.
- Exception declarations now retain their defining-name-list position explicitly, including grouped exception declarations and exception renamings.
- Existing object declaration, exception renaming, aspect-specification, and recovery paths remain intact for current consumers.
- Added AUnit regression coverage for grouped named-number declarations, qualified number initializers, grouped exception declarations, exception renamings, attached aspects, and recovery into following object declarations.

Scope:
This improves structural grammar coverage for Ada number and exception declaration internals. It is not compiler-grade legality checking for staticness, universal numeric type rules, exception renaming legality, aspect legality, declaration visibility, or grouped-name conformance.
