# Pass 678 - Variant part internal grammar

This pass improves structural Ada grammar coverage for record variant parts in the token-cursor parser.

Implemented:

- Added dedicated token-cursor productions:
  - `Production_Variant_Part_Discriminant_Name`
  - `Production_Variant_Choice_List`
  - `Production_Variant_Component_Part`
- Updated record-definition parsing so `case Discriminant is` retains the variant selector name explicitly.
- Updated `when ... =>` variant alternative parsing so each choice-list and component-part boundary is retained structurally.
- Preserved existing parsing for:
  - `Production_Variant_Part`
  - `Production_Variant`
  - `Production_Discrete_Choice_List`
  - record component declarations inside variant alternatives
  - recovery into following declarations
- Added AUnit regression coverage for variant selectors, multiple alternatives, choice lists, component parts, component declarations, and recovery after the record type.

This is structural parser coverage only. It is not compiler-grade legality checking for discriminant resolution, variant coverage, choice overlap, component legality, or record layout.
