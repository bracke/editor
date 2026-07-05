pass 306 — structured statement-node completeness pass

This pass continues the Ada language-model/parser work from pass305.

Implemented:
- Refactored Editor.Ada_Syntax_Tree so ordinary executable statement nodes directly own structured detail children.
- Removed the previous duplicate same-kind child statement shape for top-level return/raise/exit/goto/requeue/delay/abort/assignment/call/null/accept statement details.
- Kept Add_Structured_Statement_Node for compact embedded action sequences, where new child statement nodes are required.
- Added Attach_Statement_Details as the shared statement-detail builder used by both ordinary line nodes and embedded compact action nodes.
- Added compact action segment splitting for inline `when ... =>`, `else ...`, and `or ...` forms.
- Added inline `else` and same-line exception-handler action handling in the syntax-tree detail layer.
- Added AUnit coverage ensuring statement detail conversion does not insert duplicate same-kind child statements.
- Extended language_validation_check guards for direct statement-detail ownership and compact alternative splitting.

Compatibility:
- Existing statement-count metadata is retained.
- Existing syntax-tree detail node kinds remain stable.
- No rendering, command, workspace, or persistence path was changed.
- No Python or shell scripts were added.
