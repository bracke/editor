Editor Phase 579 pass314

Completeness pass focused on structured Ada representation-clause parsing after pass313.

Changes:
- Added Node_Representation_Component_Clause to Editor.Ada_Syntax_Tree.
- Record representation clauses (`for T use record ... end record;`) now open a bounded syntax-tree scope.
- Component clauses inside record representation clauses are reclassified as structured component-clause nodes instead of generic call/unknown lines.
- Component clauses retain child metadata for component target, representation item/location, and bit range.
- Added AUnit coverage for record representation component clauses.
- Extended phase579_language_validation_check guards.
- Updated README, outline docs, syntax-colouring docs, and release checklist.
