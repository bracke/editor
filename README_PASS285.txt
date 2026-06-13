Editor phase 579 pass 285

Implemented another bounded Ada statement-awareness parser pass.

Changes:
- Added Statement_Select_Terminate_Fallback metadata for compact same-line selective accept terminate fallbacks.
- Added Statement_Select_Abortable_Call metadata for compact asynchronous-select triggering calls before then abort.
- Preserved normal terminate/or/then-abort/action metadata.
- Kept all metadata parser-owned: no Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.
- Extended AUnit statement-awareness coverage and phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.
