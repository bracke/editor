Editor IDE-grade outline/semantic language model - pass 262

Implemented in this pass:
- Added Statement_Abort_Selected_Target and Statement_Abort_Multiple_Targets to
  Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Mark_Abort_Target_Details.
- Abort statements now retain bounded target-shape metadata:
  - selected-name targets, for example abort Manager.Worker;
  - comma-separated target lists, for example abort A, B, Group.Worker;
- Abort actions after executable alternatives retain the same target-shape metadata.
- Abort target metadata remains parser-owned only and does not create Outline
  rows, semantic declaration symbols, scopes, or navigation targets.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
