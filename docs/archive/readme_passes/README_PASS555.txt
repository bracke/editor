Pass 555 - discrete literal metadata through aliases

Implemented another precise static-evaluation pass for Ada representation legality.

Changes:
- Added retained discrete-literal position propagation when scalar subtype aliases and scalar derivations copy retained range metadata from a base type.
- Preserved enumeration literal position lookup for aliased types, so forms such as Primary'Pos (Blue), Primary'Succ (Green), and Primary'Base'Max (Red, Green) can feed static Size expressions.
- Seeded Boolean subtype/derived aliases with predefined False/True positions, so Truth'Succ (False) remains a valid static expression.
- Kept the implementation bounded and table-backed, reusing the existing range checks and static-value diagnostics.
- Added regression coverage for enumeration subtype aliases, derived scalar types, Base scalar functions over aliased literals, and Boolean aliases.

Scope:
- This remains a conservative retained static evaluator for IDE legality projection rather than a compiler-grade Ada static-expression engine.
