# Pass 672 - Subtype declaration internal grammar

This pass tightens structural parsing for Ada subtype declarations.

Changes:

- Added `Production_Subtype_Defining_Name`.
- Added `Production_Subtype_Declaration_Subtype_Indication`.
- Updated subtype declaration parsing so the defining identifier and subtype-indication side are retained explicitly.
- Preserved existing subtype-indication, selected-name, selected-operator selector, range-constraint, and attached-aspect parsing.
- Added AUnit regression coverage for subtype declaration internals and recovery into following declarations.

This improves structural grammar coverage for Ada subtype declaration internals. It is not compiler-grade legality checking for subtype compatibility, predicate legality, constraint legality, freezing, or visibility.
