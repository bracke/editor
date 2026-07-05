Editor pass 240

Implemented parser item 1 as an incremental statement-grammar pass.

Changes:
- Added Statement_Kind and statement-count query APIs to Editor.Ada_Language_Model.
- Added parser-owned statement awareness metadata and fingerprint updates.
- Added conservative recognition for if/case/loops/declare/begin/return/raise/goto/exit/delay/select/accept/requeue/abort/null/assignment/call statements.
- Kept record variant parts out of executable case-statement metadata.
- Added AUnit coverage for statement awareness and declaration/variant non-pollution.
- Extended language_validation_check guards.
- Updated outline, syntax-colouring, release-checklist, and README documentation.

This is not yet a full Ada statement AST or full expression parser. It is the next architecture-safe parser step toward full Ada syntax coverage while preserving the declaration-oriented Outline/semantic-colouring invariants.
