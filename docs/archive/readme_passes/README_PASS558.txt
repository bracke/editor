Pass 558 - constrained discrete subtype static metadata

This pass extends the bounded Ada representation-clause static evaluator so
constrained scalar subtype declarations preserve the base type's static scalar
category/literal metadata while narrowing the retained range.

Implemented:
- Subtype declarations of the form `subtype S is Base range L .. H` now build
  retained static range metadata from either integer bounds or discrete literal
  bounds resolved through the base type.
- Enumeration constrained subtypes keep base literal-position metadata for
  forms such as `S'Pos (Literal)`, `S'Succ (Literal)`, and `S'Width`.
- Range checks use the constrained subtype range, so adjacent scalar functions
  that step outside the subtype remain nonstatic and produce the existing
  static-value diagnostic.
- Modular constrained subtypes keep modular category metadata, so `S'Modulus`
  continues to evaluate through the base modular type category while the subtype
  range remains narrowed for value checks.

Regression coverage:
- constrained enumeration subtype `Pos`
- constrained enumeration subtype in-range `Succ`
- constrained enumeration subtype `Width`
- constrained modular subtype `Modulus`
- constrained enumeration subtype out-of-range `Succ` rejection
