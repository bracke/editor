Phase 579 pass 293

Implemented another bounded Ada parser statement-awareness increment.

Changes:
- Added refined compact conditional entry-call select else-fallback metadata:
  - Statement_Select_Else_Delay_Until
  - Statement_Select_Else_Delay_Relative
  - Statement_Select_Else_Requeue_With_Abort
  - Statement_Select_Else_Pragma_With_Arguments
- Parser now distinguishes same-line fallback subforms such as:
  - select Server.Request; else delay until Deadline; end select;
  - select Server.Request; else delay 1.0; end select;
  - select Server.Request; else requeue Target with abort; end select;
  - select Server.Request; else pragma Assert (Ready); end select;
- Existing base/action metadata is preserved:
  - Statement_Select_Else_Action
  - Statement_Select_Else_Delay
  - Statement_Select_Else_Requeue
  - Statement_Select_Else_Pragma
  - delay/requeue/pragma base metadata where already emitted by Mark_Alternative_Action
- No Outline rows, semantic symbols, scopes, declarations, or navigation targets are created from these fallback subforms.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while still remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
