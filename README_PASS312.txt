Pass 312 completeness update

This pass tightens the parser-owned Ada syntax tree after the structured select and exception-handler passes.

Implemented:
- Added first-class Node_Entry_Call_Statement syntax-tree nodes.
- Reclassified line-level entry-call alternatives directly under a select statement as structured entry-call statement nodes instead of generic call statements.
- Entry-call statement nodes now retain explicit Node_Statement_Mode metadata labelled "entry call" plus target/argument detail children.
- Added AUnit coverage for conditional select entry-call alternatives.
- Extended phase579_language_validation_check guards so the architecture cannot silently regress to generic call-only select alternatives.

No Python or shell project files were added.
