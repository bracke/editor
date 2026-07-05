Pass 444: discriminant selector-name list grammar

This pass closes a token-cursor Ada grammar gap in discriminant constraints.

Implemented:
- Added Production_Discriminant_Selector_Name.
- Added top-level arrow detection for discriminant constraint association items.
- Added Parse_Discriminant_Selector_Name_List for named discriminant associations.
- Retained selector-name lists such as Low | High => Expr structurally before parsing the value expression.
- Preserved positional discriminant constraint expressions and ordinary array index-constraint parsing.

Regression coverage:
- Extended Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness to cover Bounds (Low | High => 1).
- Added validation/release guards for the selector-name production and parser path.

Scope:
- This is syntax retention only. Compiler-grade discriminant legality, subtype conformance, staticness, and semantic disambiguation remain outside the editor parser.
