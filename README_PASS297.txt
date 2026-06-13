Editor Phase 579 — IDE-grade outline/semantic language model pass 297

Implemented another parser-owned Ada statement-awareness pass.

Changes:
- Added compact timed-entry-call select delay fallback subform metadata:
  - Statement_Select_Delay_Fallback_Delay_Until
  - Statement_Select_Delay_Fallback_Delay_Relative
  - Statement_Select_Delay_Fallback_Requeue_With_Abort
- Parser now distinguishes nested delay actions inside compact timed-select delay fallback bodies, for example:
    select Server.Request; or delay 1.0; delay until Later; end select;
- Parser now distinguishes requeue-with-abort actions inside compact timed-select delay fallback bodies, for example:
    select Server.Request; or delay until Deadline; requeue Target with abort; end select;
- Existing generic fallback-action metadata is preserved.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from these action subforms.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while still remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
