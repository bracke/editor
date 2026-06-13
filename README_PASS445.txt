Pass 445 - formal package actual-part grammar completeness

Implemented a targeted Ada token-cursor grammar pass for formal package declarations.

Changes:
- Added Production_Formal_Package_Generic_Name.
- Added Production_Formal_Package_Actual_Part.
- Added Production_Formal_Package_Actual_Box.
- Reworked formal package declaration parsing away from opaque skip-to-new/skip-to-parenthesis recovery.
- Retained the generic_package_name after `is new`, including selected names such as Ada.Containers.Ordered_Maps.
- Retained formal_package_actual_part structure for `(<>)` and ordinary generic actual parts.
- Preserved named actual selectors and `=> <>` box defaults inside formal package actual parts through the existing generic actual parser.
- Preserved formal package declarations without an explicit actual part, e.g. `with package Plain is new Generic_Plain;`.
- Added AUnit regression coverage via Test_Language_Model_Token_Cursor_Formal_Package_Actual_Part_Grammar_Completeness.
- Extended the language validation guard for the new productions.

Scope:
This is syntax retention for the editor parser/language model. It does not attempt compiler-grade legality for generic contract matching, formal package matching, default availability, or actual/formal conformance.
