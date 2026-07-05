Pass 455 - deep allocator expression grammar

Implemented another parser/language-model completeness pass focused on Ada allocator expressions.

Changes:
- Added Production_Allocator_Subtype_Indication.
- Added Production_Allocator_Qualified_Expression.
- Added Production_Allocator_Initialized_Expression.
- Added allocator-specific subtype parsing that stops before Subtype_Mark'(...) so qualified-expression allocators are not consumed as attribute-style subtype marks.
- Kept ordinary subtype constraints available for allocator subtype indications.
- Retained initialized allocator aggregate/association parts structurally.
- Added regression coverage for:
  - new Item
  - new Item'(Value => 1)
  - new Item'(others => <>)

Scope:
This is syntax retention only. Accessibility, designated subtype legality, storage pool semantics, allocator initialization legality, and expected-type aggregate resolution remain semantic/compiler work.
