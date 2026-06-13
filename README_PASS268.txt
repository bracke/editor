Phase 579 pass 268

Implemented another bounded Ada parser statement-awareness pass.

Changes:
- Added Statement_Exit_Named_Loop to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Mark_Exit_Details.
- Parser now distinguishes named-loop exits such as:
    exit Plain;
    exit Outer when Done;
- Unnamed conditional exits such as exit when Done; remain Statement_Exit + Statement_Exit_When only.
- Alternative actions such as when D => exit Outer when Done; retain named-loop exit metadata too.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from exit target names.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
