Pass 565 - Static scalar Value attribute evaluation

Implemented another bounded static-evaluation pass in the Ada semantic language model.

Changes:
- Added retained static evaluation for scalar Value attributes:
  - T'Value ("Literal_Image")
  - compatible subtype/base uses such as Primary constants initialized from Color'Value.
- Value results now feed typed discrete constants before those constants enter the reusable static environment.
- Value results now feed direct representation expressions, for example:
  - Color'Pos (Color'Value ("Green")) * 8
  - Color'Succ (Color'Value ("Red"))
- Added bounded image parsing for enumeration identifiers, Boolean images, and Character images such as "'A'".
- Preserved subtype/range compatibility so out-of-range Value-initialized constrained-subtype constants remain nonstatic and produce the existing static-value diagnostic.
- Added regression coverage for enumeration, constrained subtype, Boolean, Character, nested Value/Succ, direct Value operands, and constrained-subtype rejection.

Scope:
- This is intentionally image-level static handling. It does not attempt full Ada string-expression evaluation for Value operands.
