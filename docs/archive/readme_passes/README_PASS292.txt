pass 292 — compact select else fallback control/tasking actions

This pass extends parser-owned Ada statement-awareness metadata for compact
conditional entry-call select statements with same-line else fallbacks.

New metadata:
- Statement_Select_Else_Exit
- Statement_Select_Else_Goto
- Statement_Select_Else_Delay
- Statement_Select_Else_Requeue
- Statement_Select_Else_Abort
- Statement_Select_Else_Pragma

The parser now distinguishes fallback forms such as:

   select Server.Request; else exit Outer when Done; end select;
   select Server.Request; else goto Retry; end select;
   select Server.Request; else delay until Deadline; end select;
   select Server.Request; else requeue Target with abort; end select;
   select Server.Request; else abort Workers; end select;
   select Server.Request; else pragma Assert (Ready); end select;

The existing base/alternative metadata remains in place. These are bounded
parser fingerprints only; they do not create Outline rows, semantic symbols,
scopes, declarations, or navigation targets.
