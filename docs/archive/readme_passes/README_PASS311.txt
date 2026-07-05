pass 311 — structured exception handler nodes

This pass continues the parser-owned Ada syntax-tree completeness work from pass 310.

Changes:
- Added first-class Editor.Ada_Syntax_Tree.Node_Exception_Handler nodes.
- Reclassified line-level `when ... =>` alternatives inside exception sections as exception-handler nodes instead of generic case-style when alternatives.
- Exception handlers now retain structured child metadata for their choice list and condition text, and their executable bodies continue to be represented as structured statement sequences/actions.
- Updated the existing alternative-ownership test to expect exception handlers as their own node kind.
- Added AUnit coverage for multi-choice and `others` exception handlers.
- Extended language_validation_check guards for the new exception-handler architecture.
- Updated README, Outline docs, syntax-colouring docs, and release checklist notes.

No Python or shell scripts were added.
