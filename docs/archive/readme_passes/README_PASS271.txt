pass 271

Implemented another parser statement-awareness pass.

Changes:
- Added Statement_Then_Abort_Action to Editor.Ada_Language_Model.Statement_Kind.
- Parser now recognizes same-line asynchronous-select then-abort actions, for example:
    then abort Cleanup (Reason => Timeout);
- The embedded action is classified through the same bounded action-shape path used for alternatives, so calls and named associations are retained where visible.
- Existing Statement_Then_Abort_Alternative metadata remains preserved.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from then-abort action syntax.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README and language-feature documentation.

This continues closing parser gap nr 1 while remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
