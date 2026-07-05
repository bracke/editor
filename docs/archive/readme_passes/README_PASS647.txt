# Pass 647 - If-statement branch structure grammar

This pass improves token-cursor structural coverage for Ada if statements.

Changes:

- Added dedicated token-cursor productions for if-statement branch internals:
  - `Production_If_Statement_Condition`
  - `Production_If_Statement_Then_Statements`
  - `Production_Elsif_Statement_Condition`
  - `Production_Elsif_Statement_Then_Statements`
  - `Production_Else_Statement_Sequence`
- Updated if-statement parsing so the initial condition, then statement sequence, each elsif condition, each elsif then-sequence, and the else sequence are retained explicitly.
- Preserved the existing generic statement-sequence productions so existing consumers still see the previous broad branch markers.
- Added AUnit regression coverage for an if statement with short-circuit conditions, multiple elsif branches, an else branch, a raise statement with message inside a branch, and recovery into following statements.
- Updated README and release checklist notes.

Scope:

This improves structural grammar coverage for Ada if-statement branch structure. It is not compiler-grade legality checking for boolean expected types, reachability, statement-sequence legality, exception resolution, or control-flow analysis.
