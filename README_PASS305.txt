Phase 579 pass 305 — structured statement syntax-tree nodes

This pass converts several statement-awareness details that were previously
represented only as aggregate statement metadata into parser-owned syntax-tree
nodes.

Changes:
- Extended Editor.Ada_Syntax_Tree.Node_Kind with structured statement-detail
  nodes:
  - Node_Statement_Sequence
  - Node_Statement_Action
  - Node_Statement_Alternative
  - Node_Statement_Target
  - Node_Statement_Condition
  - Node_Statement_Selector
  - Node_Statement_Profile
  - Node_Statement_Arguments
  - Node_Statement_Message
  - Node_Statement_Mode
- Added explicit Node_Abort_Statement and Node_Terminate_Statement kinds.
- Added bounded action-sequence parsing for compact executable source shapes,
  including same-line if/then actions, case/when alternative actions, begin
  actions, loop actions, select then-abort actions, and accept do actions.
- Added structured child nodes for statement targets, conditions, selectors,
  arguments, modes, and raise-with messages.
- Kept statement-count metadata for compatibility, but the syntax tree now owns
  the actionable structure needed by later grammar/semantic passes.
- Added AUnit coverage for structured statement detail nodes.
- Extended phase579_language_validation_check guards for the new structured
  statement-node architecture.

The implementation remains deterministic, bounded, snapshot-owned, and does not
turn executable statement syntax into Outline declaration rows, semantic symbols,
scopes, or navigation targets.
