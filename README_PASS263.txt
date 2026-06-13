Editor phase 579 pass 263

Implemented another parser-owned Ada statement-awareness increment.

Changes:
- Added Statement_Requeue_Selected_Target and Statement_Requeue_With_Arguments.
- Added parser-side Mark_Requeue_Target_Details.
- Parser now distinguishes selected requeue targets such as Server.Request.
- Parser now distinguishes entry-family/argument targets such as Queue.Entry_Family (Index).
- Requeue target-shape metadata coexists with requeue-with-abort metadata.
- Requeue alternative actions after executable alternative arrows retain the same target-shape metadata.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from requeue target metadata.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README and language-feature documentation.

This continues closing parser gap nr 1 while remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
