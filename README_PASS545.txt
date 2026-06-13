Pass 545 - precise static Base attribute evaluation

This pass extends the bounded Ada static-expression evaluator used by the
semantic language model for representation legality.

Implemented:
- Retained static evaluation of chained scalar base attributes:
  - T'Base'First
  - T'Base'Last
- Retained static evaluation of range-checked base qualified expressions:
  - T'Base'(Expr)
- The support is wired through both Natural-valued and signed integer-valued
  static evaluators.
- The numeric-only static recognizer used for real-valued representation
  properties such as Small now accepts chained Base attributes in universal
  numeric expressions.
- Out-of-range T'Base'(Expr) remains nonstatic for representation purposes and
  produces the existing static-value diagnostic.

Regression coverage:
- Count'Base'Last + 1 feeding a Size clause.
- Count'Base'(8) * 2 feeding a Size clause.
- Signed Offset'Base'Last + 1 feeding a Size clause.
- Count'Base'(16) rejected as out of range.
- Count'Base'Last / 2.0 accepted for a Small clause.

Scope:
- This remains a bounded IDE-grade evaluator, not a full Ada front-end.
- It deliberately focuses on scalar Base/First/Last/qualification forms needed
  for representation and operational legality analysis.
