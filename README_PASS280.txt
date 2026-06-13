Pass 280 parser update

Implemented compact conditional entry-call select statement awareness.

Changes:
- Added Statement_Select_Entry_Call to Editor.Ada_Language_Model.Statement_Kind.
- Parser now recognizes same-line conditional entry-call select forms such as:
    select Server.Request (Item => Payload);
- The select opener retains Statement_Select.
- The embedded entry-call shape retains ordinary call metadata, including argument-list, named-association, and selected-name metadata where visible.
- The parser does not resolve the entry target and does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets from this syntax.
- Added AUnit coverage in Test_Language_Model_Statement_Awareness.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while staying bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
