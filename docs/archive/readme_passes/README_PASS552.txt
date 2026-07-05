Pass 552 - Static enumeration position evaluation

This pass extends the bounded precise static evaluator used by the Ada semantic
language model.

Implemented:
- Captures static enumeration scalar metadata from simple enumeration type
  declarations.
- Retains enumeration type position ranges for type-compatible validation.
- Resolves enumeration literal operands in T'Pos(Literal) for natural-valued
  representation expressions.
- Range-checks T'Val(N) against retained enumeration ranges before allowing the
  value to flow into representation arithmetic.
- Allows enumeration Pos values to participate in numeric-only static clauses
  such as Small while preserving universal-integer/universal-real separation.
- Adds regression coverage for enumeration Pos, Val, Small arithmetic, and
  rejected out-of-range Val operands.

Boundary:
- This is still a bounded retained semantic model, not a full Ada front end.
  Enumeration character literals and overload-disambiguated enumeration literal
  names remain outside this pass.
