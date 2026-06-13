Editor Phase 579 pass765 — formal package defaulted actual-part grammar

This pass deepens token-cursor grammar coverage for Ada generic formal package declarations whose formal_package_actual_part is omitted.

Implemented:
- Added Production_Formal_Package_Defaulted_Actual_Part.
- Tagged declarations such as `with package P is new G;` as defaulted formal package actual parts instead of requiring consumers to infer the form from missing parentheses.
- Preserved aspect parsing for defaulted formal package declarations such as `with package P is new G with Preelaborate;`.
- Preserved existing `(<>)` whole-box actual handling and parenthesized actual association handling.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Formal_Package_Defaulted_Actuals`.
- Updated validation guards, parser coverage documentation, Outline documentation, semantic-colouring documentation, and release checklist notes.

This improves structural grammar coverage for Ada formal package declarations. It is not compiler-grade generic contract conformance, formal package matching, default availability checking, overload resolution, generic semantic expansion, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.
