Pass 344 — token-cursor subprogram modifier grammar completeness

This pass extends the Ada token-cursor grammar with first-class productions for subprogram modifiers and declaration forms that were previously retained only as generic subprogram declarations/bodies.

Implemented:
- Overriding indicators, including `overriding` and `not overriding` before subprogram specifications.
- Abstract subprogram declarations such as `procedure P is abstract;`.
- Null procedure declarations such as `procedure P is null;`.
- Expression function declarations such as `function F return T is (...);`.
- Formal subprogram defaults such as `with function F return T is <>;`.
- Shared subprogram construct parsing for ordinary, modified, instantiated, stub, expression, null, and abstract subprogram forms.
- AUnit coverage for overriding indicators, null procedures, expression functions, abstract subprogram declarations, ordinary declarations, and formal subprogram defaults.
- Validation guards for the new token-cursor productions and test.

The grammar remains deterministic, bounded, editor-owned, and independent of external parser generators.
