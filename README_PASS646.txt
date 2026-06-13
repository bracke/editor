Editor Phase 579 - Pass 646

Focus: conditional-expression elsif branch grammar.

Changes:
- Added dedicated token-cursor productions for conditional-expression elsif branch internals:
  - Production_Elsif_Expression_Condition
  - Production_Elsif_Expression_Then_Dependent_Expression
- Updated conditional-expression parsing so `elsif` conditions and `elsif ... then` dependent expressions are retained separately from the initial `if` condition and first `then` expression.
- Preserved existing structural parsing for initial if conditions, then dependent expressions, else dependent expressions, nested case expressions, qualified expressions, and raise expressions.
- Added AUnit regression coverage for multi-elsif conditional expressions and recovery into a following object declaration.
- Updated README and release checklist entries.

This improves structural grammar coverage for Ada conditional-expression elsif branches. It is not compiler-grade legality checking for expected-type resolution, branch type conformance, staticness, or conditional-expression placement.
