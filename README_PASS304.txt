Pass 304 completeness pass

This pass continues the Ada syntax-tree foundation work by widening parser-owned statement-shape coverage and fixing a compile-risk regression.

Implemented:
- Added syntax-tree node kinds for labels, delay statements, exit statements, goto statements, and requeue statements.
- Taught `Editor.Ada_Syntax_Tree.Classify_Line` to classify those control/tasking statement shapes directly instead of falling back to calls, objects, or unknown nodes.
- Attached bounded expression/name metadata under delay, exit, goto, requeue, and raise-with statement nodes.
- Added nested association operand metadata for named associations so later grammar passes can walk association names and values separately.
- Treated Ada character literals as literal expression nodes in the syntax-tree layer.
- Removed a duplicate `Node_Type_Declaration | Node_Subtype_Declaration` case alternative in `Attach_Syntax_Details`.
- Added AUnit coverage for control-statement syntax-tree nodes and their child metadata.
- Extended phase579 language validation guards and documentation.

Still conservative:
- The syntax tree remains a bounded source-shape tree, not a full Ada grammar AST.
- Statement syntax still does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets.
- No type resolution, overload resolution, or Ada legality checking is performed.
