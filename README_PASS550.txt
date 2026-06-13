Pass 550 - precise static scalar position/value attributes

This pass extends the retained Ada semantic static evaluator used by
representation-clause legality with bounded support for discrete scalar
position and value attributes over retained integer/modular scalar metadata.

Implemented:
- Natural-valued static evaluation for T'Pos(X) and T'Val(X).
- Chained base forms T'Base'Pos(X) and T'Base'Val(X).
- Signed static evaluation for Pos/Val so negative integer subtype bounds can
  participate in later representation expressions.
- Numeric-only recognition for Pos/Val so Small-style numeric clauses can use
  discrete scalar attributes inside universal-real arithmetic.
- Operand/range validation against retained integer/modular range metadata;
  out-of-range Pos/Val operands remain nonstatic and receive the existing
  static-value diagnostics.

Regression coverage:
- Size clauses using T'Pos, T'Val, and T'Base'Val.
- Signed range bounds using T'Pos and T'Base'Val.
- Small clause accepting a discrete Pos value in real arithmetic.
- Rejection of out-of-range Pos and Val values.
