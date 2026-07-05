# Editor — Pass 723

Pass 723 improves structural Ada grammar coverage for subtype indications.

## Changed

- Added token-cursor productions:
  - `Production_Subtype_Mark`
  - `Production_Subtype_Null_Exclusion`
  - `Production_Subtype_Range_Constraint`
  - `Production_Subtype_Digits_Constraint`
  - `Production_Subtype_Delta_Constraint`
  - `Production_Subtype_Index_Constraint`
  - `Production_Subtype_Discriminant_Constraint`
  - `Production_Subtype_Constraint_Recovery_Boundary`
- Improved structural parsing for subtype indications with:
  - explicit subtype-mark retention
  - `not null` null-exclusion markers in subtype contexts
  - range constraints
  - digits constraints
  - delta constraints
  - index constraints
  - named discriminant constraints
  - malformed constraint recovery into following declarations
- Added AUnit coverage:
  - `Test_Language_Model_Token_Cursor_Subtype_Indication_Depth_Grammar_Completeness`

## Scope

This improves structural grammar coverage for Ada subtype indications and their constraint forms. It is not compiler-grade legality checking for subtype compatibility, constraint conformance, staticness, accessibility, discriminant legality, index dimensionality, range bounds, or expected-type analysis.
