Editor pass360 — expression-aware overload completeness

This pass extends the conservative expression-aware overload resolver added in
passes 358-359.

Implemented:
- `Infer_Expression_Type_In_Scope` now recognizes unary `not` expressions.
  Boolean operands infer `Boolean`; retained quoted unary operator overloads are
  consulted for non-predefined cases before degrading.
- `Infer_Expression_Type_In_Scope` now recognizes unary `abs` expressions.
  Retained quoted unary `"abs"` overloads are consulted first; otherwise the
  operand type is retained when it is known.
- Top-level membership expressions `in` and `not in` infer `Boolean` only when
  both sides can be typed.
- Top-level exponentiation `**` and concatenation `&` are routed through the same
  bounded operator-expression path as other operators.
- Unknown unary or membership operands still do not become wildcard overload
  actuals.

Tests:
- Added `Test_Resolver_Expression_Aware_Unary_And_Membership`.

Updated documentation/release guards:
- README.md
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
- tools/release_check.adb

No Python, shell scripts, `.pyc`, parser generators, rendering-side parsing, or
external LSP/compiler integration were added to the project.
