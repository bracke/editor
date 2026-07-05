Editor  IDE-grade outline/semantic language model pass 295

Implemented compact timed entry-call select delay-fallback action metadata.

Changes:
- Added Statement_Select_Delay_Fallback_Action.
- Added select-delay fallback action subforms for null, call, assignment, return, raise, and code statements.
- Parser now trims trailing compact end select text before classifying fallback bodies after `or delay ...;`.
- Embedded action metadata remains parser-owned only and does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check.
- Updated README and language-feature docs.
