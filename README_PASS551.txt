Pass 551 - unary abs static expression evaluation

Implemented another bounded Ada static-evaluation pass for representation-expression legality.

Changes:
- Added Ada unary `abs` recognition to Natural-valued static representation expressions.
- Added signed integer static-expression support for unary `abs` so signed range bounds can be derived from absolute values.
- Added numeric-only static recognition for `abs` over universal-integer and universal-real operands, preserving operand kind for later compatibility checks.
- Preserved integer-only operator rejection after real-valued abs expressions, for example `abs (-1.0) mod 2` remains nonstatic for `Small`.
- Added regression coverage for:
  - `Size` using `abs (-8) * 2`
  - signed range bounds using `-abs (4) .. abs (-3)`
  - later `Size` arithmetic using `abs (Narrow'First)`
  - `Small` accepting real-valued `abs` arithmetic
  - `Small` rejecting real-valued `abs` followed by `mod`
