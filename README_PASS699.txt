# Editor Phase 579 - Pass 699

Pass 699 deepens structural token-cursor coverage for Ada variant records.

## Implemented

- Added variant-record grammar productions:
  - `Production_Variant_Others_Choice`
  - `Production_Variant_Choice_Separator`
  - `Production_Variant_Choice_Arrow`
  - `Production_Nested_Variant_Part`
  - `Production_Variant_Recovery_Boundary`
- Improved parsing for:
  - `case Discriminant is` variant parts
  - `when Choice | Choice =>` alternatives
  - `when others =>` alternatives
  - nested variant parts inside variant component parts
  - malformed `when` alternatives with missing `=>`
  - recovery into following declarations after malformed variant records
- Added AUnit regression coverage:
  - `Test_Language_Model_Token_Cursor_Variant_Record_Depth_Grammar_Completeness`
- Updated validation and release documentation.

## Scope

This improves structural grammar coverage for Ada variant records. It is not
compiler-grade legality checking for discriminant dependence, variant choice
coverage, duplicate choices, component legality, nested variant legality,
visibility, representation, or staticness rules.
