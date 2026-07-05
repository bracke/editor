Pass 459 - Representation Item Identity Legality

Focus:
- Extend the Ada legality diagnostics layer for representation items whose identity must be unique.

Changes:
- Added Legality_Duplicate_Enumeration_Representation_Literal.
- Added Legality_Duplicate_Record_Component_Representation.
- Enumeration representation clauses now diagnose duplicate literal associations such as:
    for Colour use (Red => 1, Red => 2, Green => 3);
- Record representation clauses now diagnose repeated component clauses such as:
    for Pair use record
       A at 0 range 0 .. 3;
       A at 1 range 0 .. 3;
    end record;
- Existing duplicate static enum-value and static bit-overlap diagnostics are preserved.
- Added Test_Language_Model_Legality_Representation_Item_Identity_Pass.

Notes:
- This is still a bounded editor language-model legality pass, not full compiler-equivalent Ada legality.
