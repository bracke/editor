Editor pass768 — qualified-expression selected subtype-mark depth

This pass deepens token-cursor grammar for selected subtype marks in qualified expressions.

Implemented:
- Reused Production_Qualified_Expression_Selected_Subtype_Mark for selected subtype marks before a qualification apostrophe.
- Tagged ordinary selected subtype marks such as Math.Count'(1).
- Tagged selected operator-literal subtype marks such as Operator_Types."+"'(5).
- Tagged allocator qualified-expression selected subtype marks such as new Math.Count'(6).
- Preserved existing Production_Selected_Name, Production_Selected_Operator_Selector, Production_Qualified_Expression_Subtype_Mark, Production_Qualified_Expression_Apostrophe, Production_Qualified_Expression_Operand, and Production_Allocator_Qualified_Expression metadata.
- Extended AUnit coverage in Test_Language_Model_Token_Cursor_Qualified_Expression_Part_Grammar_Completeness.

This improves structural grammar coverage for Ada qualified expressions and selected subtype marks. It is not compiler-grade conversion/qualification disambiguation, subtype resolution, operator literal legality checking, allocator accessibility checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
