Pass 564 - Parenthesized discrete static expression retention
=============================================================

This pass continues the precise type-compatible static evaluation work from
passes 539-563.

Implemented changes
-------------------

- Added whole-parenthesized discrete static expression evaluation for retained
  typed discrete constants and scalar attribute operands.
- Discrete static defaults now accept forms such as:
  - `Default_Color : constant Color := (Green);`
  - `Nested_Color  : constant Color := ((Default_Color));`
  - `From_Succ     : constant Color := Color'Succ ((Default_Color));`
  - `From_Qualified : constant Color := Color'((Blue));`
- Parentheses are stripped only when they enclose the whole expression, avoiding
  accidental acceptance of aggregate-like or comma-separated fragments.
- Existing subtype/range compatibility checks remain in force after unwrapping.
- Unknown parenthesized discrete names remain nonstatic and continue to produce
  the existing static-value diagnostic.

Regression coverage
-------------------

Added semantic regression coverage for:

- parenthesized enumeration literal constants feeding `T'Pos`;
- nested parenthesized discrete constants;
- parenthesized operands to scalar attribute functions such as `T'Succ`;
- parenthesized qualified discrete defaults;
- parenthesized Character literals containing parenthesis characters;
- rejection of unknown parenthesized discrete constants.
