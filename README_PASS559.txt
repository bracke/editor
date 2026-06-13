Pass559: typed discrete static constants

This pass extends the retained Ada static evaluator so typed discrete constants can be used as static operands in representation expressions.

Implemented:
- added a bounded retained table for static discrete constants keyed by constant name and subtype mark;
- registered typed enumeration/Boolean/Character-style constants when their default literal or earlier retained discrete constant is compatible with the subtype range;
- extended discrete operands for Pos/Succ/Pred/Min/Max-style scalar attribute evaluation to resolve retained typed constants, not only raw literals;
- extended the numeric-only static recognizer for attribute Pos operands so Small-style clauses can recognize typed discrete constants through Pos;
- kept invalid/unknown discrete constants out of the static environment so later representation clauses still produce the existing static-value diagnostic.

Regression coverage:
- Color'Pos (Default_Color) in a Size clause;
- Color'Succ (Default_Color) in a Size clause;
- a static discrete constant chained through another constant;
- an unknown discrete constant rejected as nonstatic in a representation expression.
