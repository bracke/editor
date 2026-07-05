Pass595: constrained String subtype bound attributes are now usable inside later static String index constraints.

- Extended the signed static integer evaluator to consult retained constrained String subtype bound metadata for `'First`, `'Last`, and `'Length` operands.
- This allows later subtypes such as `subtype Derived_Name is String (Offset_Name'First .. Offset_Name'Last);` to retain bounds instead of losing static metadata.
- The derived subtype metadata feeds existing paths for subtype attributes, constrained qualification length checks, and qualified-prefix indexing/slicing.
- Added regression coverage for a derived constrained String subtype using earlier constrained subtype bound attributes in its index constraint.
