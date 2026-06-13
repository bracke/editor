Pass561: subtype-compatible discrete static constants

Implemented another bounded precision pass for static representation-expression evaluation.

What changed:
- Added retained subtype-alias root tracking for scalar subtypes.
- Discrete constants declared with constrained subtype marks can now be used through the base scalar type's static attribute functions.
- Discrete constants declared with a base scalar type can now be used through compatible constrained subtype attribute prefixes when the value is inside the constrained subtype range.
- Out-of-range subtype-prefix uses remain nonstatic and produce the existing static-value diagnostic.
- Canonicalized Standard.Boolean / Boolean and Standard.Character / Character for retained discrete-constant compatibility.

Examples now covered:
- `Default_Primary : constant Primary := Green;`
- `Color'Pos (Default_Primary) * 8`
- `Default_Color : constant Color := Green;`
- `Primary'Pos (Default_Color) * 8`
- `Primary'Pos (Bad_Color)` rejected when `Bad_Color` denotes a value outside `Primary`.

Regression coverage:
- subtype constant flowing into base `T'Pos`
- base constant flowing into constrained subtype `T'Pos`
- constrained subtype out-of-range constant rejection
