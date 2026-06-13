Pass 549 - precise static scalar successor/predecessor attributes

This pass extends the retained Ada semantic static evaluator used by
representation-clause legality with bounded support for discrete scalar
successor and predecessor attributes.

Implemented:
- Natural-valued static evaluation for T'Succ(X) and T'Pred(X).
- Chained base forms T'Base'Succ(X) and T'Base'Pred(X).
- Signed static evaluation for Succ/Pred so range bounds can feed later
  representation expressions.
- Numeric-only recognition for Succ/Pred so Small-style expressions can use
  discrete scalar attributes inside universal-real arithmetic.
- Operand and result range validation against retained integer/modular range
  metadata; out-of-range successors/predecessors remain nonstatic and receive
  the existing static-value diagnostics.

Regression coverage:
- Size clauses using T'Succ, T'Pred, and T'Base'Succ.
- Signed range bounds using T'Pred and T'Base'Succ.
- Small clause accepting a discrete Succ value in real arithmetic.
- Rejection of out-of-range Succ and Pred values.
