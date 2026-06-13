Editor Phase 579 pass 265

This pass extends Ada parser-owned statement-awareness metadata with explicit access dereference statement shapes.

Implemented changes:
- Added Statement_Call_Access_Dereference to Editor.Ada_Language_Model.Statement_Kind.
- Added Statement_Assignment_Access_Dereference to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side detection for access-to-subprogram call statements such as Callback.all; and Handler.all (Item);.
- Added parser-side detection for assignment targets such as Access_Obj.all := Value;.
- Alternative call and assignment actions after executable arrows retain the same .all shape metadata.
- These markers remain bounded parser fingerprints only and do not create Outline rows, semantic symbols, scopes, declarations, or navigation targets.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.
