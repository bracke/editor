Editor — Pass922

This pass improves structural grammar recovery for malformed Ada index and discriminant constraints at reserved boundaries.

Changes:
- Added Production_Index_Constraint_Missing_Item_Recovery_Boundary.
- Added Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary.
- Added Production_Discriminant_Association_Missing_Expression_Recovery_Boundary.
- Added Production_Discriminant_Constraint_Reserved_Boundary_Recovery_Boundary.
- Refined index constraint parsing so forms such as Vector (else) and Vector (1 .. else) do not fabricate reserved boundary tokens as index items or bound expressions.
- Refined discriminant constraint parsing so forms such as Rec (D => else) do not fabricate reserved boundary tokens as discriminant actual expressions.
- Added AUnit regression Test_Language_Model_Token_Cursor_Index_Discriminant_Constraint_Reserved_Boundary_Recovery_Pass922.
- Updated validation guard markers, coverage docs, syntax-colouring docs, release checklist, and README.

This improves structural grammar coverage for malformed Ada index and discriminant constraints. It is not compiler-grade constraint legality checking, subtype compatibility checking, static expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
