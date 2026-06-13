Pass 562 - Attribute-initialized discrete static constants

Implemented another precise static-evaluation pass in the Ada semantic language model.

Changes:
- Retains typed discrete constants initialized from scalar attribute functions that return discrete values:
  - T'Val (N)
  - T'Base'Val (N)
  - T'Succ (X)
  - T'Pred (X)
  - T'Min (X, Y)
  - T'Max (X, Y)
- Allows those retained constants to feed later static representation expressions such as T'Pos (Default) * 8.
- Preserves subtype compatibility and constrained-subtype range checks when an attribute-initialized constant is declared with a narrowed subtype.
- Rejects out-of-range attribute-initialized discrete constants so they do not enter the reusable static environment.
- Added regression coverage for Val, Base'Val, Succ, Pred, Min, Max, and constrained-subtype rejection.
