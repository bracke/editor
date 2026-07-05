Pass 602 - Unconstrained String constant Range copy

- Extended copied String range-attribute constraint retention for named unconstrained static String constants.
- Later constrained String subtypes can now derive bounds from forms such as `subtype Constant_Range_Name is String (Qualified_Name'Range);` where `Qualified_Name` is a retained `constant String` without explicit constrained-object bounds.
- The copied range uses the normal String lower bound `1` and the retained static image length as `Last`.
- Existing subtype attributes, constrained qualification checks, and qualified-prefix indexing/slicing paths reuse the derived bounds.
- Added regression coverage for unconstrained static String constant `Range` constraints feeding representation static values.
