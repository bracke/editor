Pass 282 — compact timed entry-call select delay fallback metadata

Implemented parser-owned statement-awareness metadata for compact timed entry-call select forms such as:

   select Server.Request (Item => Payload); or delay until Deadline; end select;
   select Server.Other; or delay 1.0; end select;

Changes:
- Added Statement_Select_Delay_Fallback.
- Added Statement_Select_Delay_Fallback_Until.
- Added Statement_Select_Delay_Fallback_Relative.
- Parser stamps base delay metadata for compact select delay fallbacks.
- Added AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README and language docs.

The metadata remains bounded parser-owned statement awareness only. It does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.
