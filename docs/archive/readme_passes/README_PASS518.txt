Pass 518 - value-bearing GNAT representation pragma unification

Implemented another focused representation/operational unification pass.

Changes:
- Corrected generic representation pragma lowering for value-bearing GNAT pragmas:
  - pragma Linker_Section (Entity, Section_Name)
  - pragma Machine_Attribute (Entity, Attribute_Name)
- These pragmas now preserve their second argument as Item_Text instead of defaulting to the Boolean placeholder True.
- Kept them on the shared Representation_Kind_For resolver path, so their pragma, aspect, and attribute-definition forms now retain equivalent explicit representation kinds and values.
- Added regression coverage to the representation pragma unification test proving Linker_Section and Machine_Attribute pragmas retain their string payloads.
