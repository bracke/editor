Phase 579 pass 279

Implemented another bounded Ada parser statement-awareness increment.

Changes:
- Added Statement_Goto_Label_Target to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Mark_Goto_Details.
- Parser now records visible label-target shape for ordinary goto statements such as `goto Retry;`.
- Parser now records the same target-shape metadata for executable alternative actions such as `when A => goto Done;`.
- Existing base metadata remains intact: Statement_Goto and Statement_Alternative_Goto where applicable.
- Goto label targets are not learned as declarations, Outline rows, semantic symbols, scopes, or navigation targets.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while still remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
