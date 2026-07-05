pass 298 — timed-select fallback call-shape refinement

This pass refines the Ada parser's bounded statement-awareness metadata for
compact timed entry-call select delay fallback bodies.

Implemented:
- Added select-delay-fallback call-shape metadata:
  * Statement_Select_Delay_Fallback_Call_With_Arguments
  * Statement_Select_Delay_Fallback_Call_With_Named_Association
  * Statement_Select_Delay_Fallback_Call_Selected_Name
  * Statement_Select_Delay_Fallback_Call_Access_Dereference
  * Statement_Select_Delay_Fallback_Call_Entry_Family_Index
- Parser now preserves visible fallback call shape for forms such as:
    select Server.Thirteenth; or delay 1.0; Router.Target (Slot) (Name => Payload); end select;
- Existing base call metadata is preserved.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from these fallback action forms.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README and language-intelligence documentation.
