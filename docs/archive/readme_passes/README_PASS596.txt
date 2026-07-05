Pass596: constrained String object bound attributes now feed later static String index constraints.

- Extended the signed static integer evaluator to consult retained constrained String object bound metadata for `'First`, `'Last`, and `'Length` operands.
- This allows later subtypes such as `subtype Object_Derived_Name is String (Offset_Object'First .. Offset_Object'Last);` to retain bounds instead of exposing object bounds only to representation expressions.
- The derived subtype metadata feeds existing paths for subtype attributes, constrained qualification length checks, and qualified-prefix indexing/slicing.
- Added regression coverage for a derived constrained String subtype using earlier constrained String object bound attributes in its index constraint.
