Pass575: Static string slicing in representation evaluation

Implemented bounded static evaluation for retained one-dimensional static string slices.

Changes:
- Added Static_String_Slice_Value for retained static string constants.
- Static string expressions can now treat S (L .. H) as a String-valued static operand when S is retained and both bounds are static in-range integer expressions.
- Slice results can initialize additional static string constants and feed scalar Value through concatenation, for example:
  - Prefix : constant String := Green_Name (1 .. 3);
  - Color'Value (Prefix & "en")
  - Color'Value (Green_Name (1 .. 2) & "een")
- Slice-derived static string constants expose existing String'Length/First/Last attributes.
- Out-of-range string slices remain nonstatic and continue to produce the existing static-value diagnostic when used by representation clauses.
- Added regression coverage for named slices, direct slices, slice-derived Length, and out-of-range slice rejection.
