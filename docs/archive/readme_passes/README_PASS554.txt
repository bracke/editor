Pass 554 - discrete literal operands for static scalar functions

Implemented another precise static-evaluation pass for Ada representation legality.

Changes:
- Extended Natural-valued static representation expression evaluation so scalar function operands may be retained discrete literals, not only numeric positions.
- Extended signed static-expression evaluation for the same literal operands.
- Covered direct and chained Base forms for:
  - T'Min(Literal, Literal)
  - T'Max(Literal, Literal)
  - T'Succ(Literal)
  - T'Pred(Literal)
  - T'Base'Min/Max/Succ/Pred(...)
- Reused retained enumeration/predefined-discrete literal position metadata and existing range checks.
- Out-of-range literal successor/predecessor results remain nonstatic and use the existing static-value diagnostics.
- Added regression coverage for enumeration literal operands in Succ, Pred, Min, and Base'Max representation expressions.

Scope:
- This remains a bounded retained static evaluator for semantic/IDE legality projection, not a full Ada front-end evaluator.
