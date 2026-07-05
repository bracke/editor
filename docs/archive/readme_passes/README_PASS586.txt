Pass 586 - Constrained String qualification length checks

- Added bounded retained length metadata for simple constrained String subtypes such as String (1 .. 5).
- String-compatible qualified expressions now reject statically known values whose component count does not match the constrained subtype length.
- Static String constant retention applies the same constrained-subtype length check, preventing mismatched constants from feeding later Length/Value representation expressions.
- Preserved bound sliding semantics at the component-count level: only the number of components is checked, not the lower-bound spelling.
- Added regression coverage for both accepted Small_Name'("Green") and rejected Small_Name'("Purple") static paths.
