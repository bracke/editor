Editor Phase 579 pass 266

Implemented another bounded Ada statement-parser increment.

Changes:
- Added Statement_Call_Entry_Family_Index to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Call_Has_Entry_Family_Index detection for call statements with an entry-family-like index group followed by a parameter group.
- Added Alternative_Call_Has_Entry_Family_Index for executable alternative actions after =>.
- Calls such as Server.Family (Index) (Item); retain ordinary call metadata plus entry-family call-shape metadata.
- Alternative actions such as when A => Router.Target (Slot) (Payload); retain ordinary call, alternative-call, selected-name call, argument-list call, and entry-family call-shape metadata.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from this syntax.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check guards.
- Updated README, Outline docs, syntax-colouring docs, and release checklist.

This continues closing parser gap nr 1 while remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
