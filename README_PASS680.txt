# Pass 680 - Array type definition internal grammar

- Added `Production_Array_Index_Subtype_Definition` for unconstrained array index subtype definitions inside ordinary array type definitions.
- Added `Production_Array_Component_Definition` for the component-definition side after `of` in ordinary array type definitions.
- Preserved existing `Production_Index_Subtype_Definition`, `Production_Index_Constraint`, range parsing, subtype-indication parsing, and formal-array productions.
- Retained `aliased` array component definitions structurally before parsing the component subtype indication.
- Extended AUnit array grammar coverage for unconstrained index subtype definitions, constrained array ranges, component definitions after `of`, and aliased array components.

This improves structural grammar coverage for Ada array type definition internals. It is not compiler-grade legality checking for index subtype legality, component subtype compatibility, constrained/unconstrained array rules, aliased component legality, or visibility.
