Editor Phase 579 - Pass 671
===========================

Focus: generic formal type declaration-head grammar.

Changes:
- Added `Production_Formal_Type_Defining_Name` to retain the defining name side of generic formal type declarations explicitly.
- Added `Production_Formal_Type_Discriminant_Part` to retain the declaration-head discriminant part before ordinary discriminant parsing.
- Preserved existing deep formal type definition parsing for private, derived, scalar, array, access, and interface formal type categories.
- Added AUnit coverage for known and unknown formal type discriminant parts, attached aspects, and recovery into following declarations.
- Updated README and release checklist notes.

Scope:
This improves structural grammar coverage for Ada generic formal type declaration heads. It is not compiler-grade legality checking for discriminant legality, formal type contract conformance, aspect placement, or subtype compatibility.
