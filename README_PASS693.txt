# Editor Phase 579 - Pass 693

This pass deepens structural Ada name grammar coverage in the token-cursor
parser while preserving the existing language-model architecture and editor
invariants.

Implemented in this pass:

- Added explicit selected-name prefix retention via
  `Production_Selected_Name_Prefix`.
- Added shared literal selector retention via
  `Production_Selected_Literal_Selector` while preserving the existing
  operator-symbol and character-literal selector productions.
- Added allocator subtype markers:
  - `Production_Allocator_Subtype_Mark`
  - `Production_Allocator_Access_Subtype`
- Added a qualification-boundary marker:
  - `Production_Qualified_Expression_Apostrophe`
- Extended token-cursor parsing so selected operator/character literal
  selectors also remain visible as name components for resolver and semantic
  colouring consumers.
- Added AUnit regression coverage for selected literal names, qualified
  expression apostrophe boundaries, named and access-subtype allocators, and
  recovery into following declarations.
- Updated validation guards, README notes, Outline docs, semantic-colouring
  docs, and release checklist.

This improves structural grammar coverage for Ada name families.  It is not
compiler-grade legality checking for overload resolution, visibility,
character/operator literal resolution, allocator accessibility, subtype-mark
legality, qualified-expression typing, or selected-name legality.
