pass 307 — compact embedded control-flow statement nodes

This pass completes another part of the structured statement-node conversion introduced in passes 305 and 306.

Changes:
- `Editor.Ada_Syntax_Tree.Statement_Node_Kind` now classifies compact embedded control-flow/action segments as their proper node kinds:
  - if / elsif / else
  - case / when
  - loop / while / for
  - declare / begin
  - select
  - exception handlers
- Compact action sequences therefore retain inline control-flow shape as structured syntax-tree nodes instead of generic call-statement fallbacks.
- Added AUnit coverage: `Test_Language_Model_Syntax_Tree_Compact_Control_Actions_Are_Structured`.
- Extended `language_validation_check` to guard the compact embedded control-flow node conversion and its test coverage.
- Updated README and language-intelligence documentation.

Compatibility:
- Existing statement-count metadata remains intact.
- Outline remains declaration-focused and does not create rows for executable statements.
- Semantic colouring remains conservative and does not learn executable targets as declarations.
