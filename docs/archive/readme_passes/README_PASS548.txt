Pass 548 - precise static evaluation: scalar Min/Max attributes

This pass extends the retained static-expression evaluator used by the Ada
semantic language model for representation and operational item legality.

Implemented:
- Static evaluation for scalar attribute functions T'Min(X, Y) and T'Max(X, Y).
- Static evaluation for chained scalar base forms T'Base'Min(X, Y) and
  T'Base'Max(X, Y).
- Range compatibility checks for both Min/Max operands before the value is
  admitted into natural-valued representation expressions.
- Signed static evaluation support for Min/Max so signed bounds can be used in
  later retained subtype/range metadata.
- Regression coverage for natural Min/Max, Base'Max, signed Min/Max bounds, and
  out-of-range Max operands producing static-value diagnostics.

This remains a bounded IDE-grade static evaluator, not a complete Ada compiler
front end, but it closes another precise type-compatible static-attribute gap.
