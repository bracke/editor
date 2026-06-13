Editor Phase 579 - Pass 675
===========================

Focus
-----
Improve structural grammar coverage for Ada type declaration internals.

Changes
-------
- Added `Production_Type_Defining_Name` for type declaration defining names.
- Added `Production_Type_Discriminant_Part` for known and unknown type discriminant parts.
- Updated ordinary type declaration parsing so full, plain incomplete, tagged incomplete, and discriminated private/type declarations retain the declaration head structure explicitly.
- Preserved existing type-definition parsing for enumeration, record, private, incomplete, and tagged incomplete forms.
- Added AUnit coverage for full type declarations, incomplete declarations, tagged incomplete declarations, known discriminants, unknown discriminants, enumeration definitions, and recovery into following declarations.

Boundary
--------
This improves structural grammar coverage for Ada type declaration heads and discriminant parts. It is not compiler-grade legality checking for type completion, discriminant legality, representation, freezing, visibility, or subtype compatibility.
