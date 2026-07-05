Pass 296 parser update
======================

Implemented another bounded Ada statement-awareness increment in the parser/language model.

Changes:
- Added compact timed-entry-call delay fallback action metadata for additional control/tasking/pragma action forms:
  - Statement_Select_Delay_Fallback_Exit
  - Statement_Select_Delay_Fallback_Goto
  - Statement_Select_Delay_Fallback_Delay
  - Statement_Select_Delay_Fallback_Requeue
  - Statement_Select_Delay_Fallback_Abort
  - Statement_Select_Delay_Fallback_Pragma
  - Statement_Select_Delay_Fallback_Pragma_With_Arguments
- Parser now recognizes compact timed-select fallback bodies such as:
  - select Server.Request; or delay 1.0; exit Outer when Done; end select;
  - select Server.Request; or delay until Deadline; goto Retry; end select;
  - select Server.Request; or delay 1.0; delay until Later; end select;
  - select Server.Request; or delay until Deadline; requeue Target with abort; end select;
  - select Server.Request; or delay 1.0; abort Workers; end select;
  - select Server.Request; or delay until Deadline; pragma Assert (Ready); end select;
- Existing base metadata remains preserved via the common alternative-action classifiers.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from these fallback action forms.
- Extended AUnit coverage and language_validation_check guards.
- Updated README and language feature docs.

This remains bounded parser statement metadata, not a full Ada statement/name/expression AST.
