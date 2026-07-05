Editor pass 252

Implemented another Ada parser statement-awareness pass.

Changes:
- Added Statement_Call_Selected_Name to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Call_Has_Selected_Name.
- Selected-name procedure/entry calls such as Console.Flush; and Worker.Start (Priority => High); remain ordinary Statement_Call metadata while also retaining selected-name call shape.
- Selected-name calls with named associations still retain Statement_Call_With_Named_Association.
- Code statements remain separate from call statements.
- Fixed a stale duplicated assertion string in the statement-awareness AUnit test while extending the same test coverage.
- Extended language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This remains bounded parser metadata and does not create Outline rows, semantic declaration symbols, scopes, or navigation targets.
