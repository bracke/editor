Phase 579 pass 308: select then-abort syntax-tree detail completeness

This pass tightens the parser-owned Ada syntax tree after the structured statement-node conversion.

Implemented changes:
- Compact statement sequences now recognize `then abort` segments as structured abortable alternatives instead of degrading them to call-like action text.
- Inline `select ... then abort ...` statements now retain both sides:
  - a `triggering` `Node_Statement_Mode` and statement sequence for the triggering statement;
  - a `then abort` `Node_Statement_Mode` and statement sequence for the abortable part.
- Compact `elsif ... then ...` tails now also emit explicit statement-alternative metadata before the nested `Node_Elsif_Part` node.
- Added AUnit coverage for select then-abort triggering and abortable statement-tree ownership.
- Extended the phase language validation guard so future regressions must retain the select then-abort structured details and test coverage.

No Python or shell project files were added.
