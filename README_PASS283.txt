Phase 579 pass 283

Implemented another Ada declaration-parser statement-awareness pass.

Changes:
- Added Statement_Select_Then_Abort_Fallback to Editor.Ada_Language_Model.Statement_Kind.
- Parser now recognizes compact asynchronous select forms such as:
    select Start_Work; then abort Cleanup (Reason => Timeout); end select;
- Existing then-abort alternative/action metadata is preserved.
- Embedded abortable action shape retains call/named-association metadata where visible.
- No Outline rows, semantic symbols, scopes, declarations, or navigation targets are created from this syntax.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check guards.
- Updated README and language-feature documentation.

This remains bounded statement-awareness metadata, not a full Ada statement/name/expression AST.
