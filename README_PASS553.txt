Pass 553 - predefined discrete static attribute precision

Scope
- Continues the precise type-compatible static-evaluation work from pass552.
- Focuses on predefined discrete scalar attributes that were still missing after
  retained user-defined enumeration literal support.

Implemented
- Added bounded predefined range metadata for Boolean and Character, including
  selected-name standard forms where retained as Standard.Boolean or
  Standard.Character.
- Added retained discrete literal position evaluation for:
  - Boolean'Pos (False) => 0
  - Boolean'Pos (True)  => 1
  - Character'Pos ('A') => 65 for ordinary single-code-unit character literals.
- Reused the new predefined range metadata for Boolean'Val and Character'Val
  range validation in static representation expressions.
- Wired predefined discrete Pos/Val through:
  - Natural-valued representation expressions
  - signed static expression evaluation via the shared literal position helper
  - numeric-only recognition used by real-valued properties such as Small
- Preserved rejection of out-of-range Val operands, so e.g. Boolean'Val (2)
  remains nonstatic and produces the existing static-value diagnostic.

Regression coverage
- Boolean'Pos (True) in a Size expression.
- Boolean'Val (1) in a Size expression.
- Character'Pos ('A') in a Size expression.
- Boolean'Pos / Character'Pos participation in Small numeric arithmetic.
- Out-of-range Boolean'Val (2) rejected as nonstatic.

Notes
- Character literal handling is intentionally bounded to ordinary single-code-unit
  source character literals. Wider character encodings and escaped spellings remain
  future lexer-level work.
