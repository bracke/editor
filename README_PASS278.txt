Pass 278 parser statement-awareness update

Implemented compact same-line handled-sequence begin action metadata.

Changes:
- Added Statement_Begin_Action to Editor.Ada_Language_Model.Statement_Kind.
- Added Mark_Compact_Begin_Action_Details in Editor.Ada_Declaration_Parser.
- Parser now recognizes compact forms such as:
  * begin Worker.Deliver (Name => Item); end P;
  * begin Status := Ready; end P;
  * begin return Value; end P;
  * begin raise Program_Error with "bad"; end P;
- Embedded action metadata is retained where visible: call, named association,
  assignment, return expression, and raise-with-message.
- No Outline rows, semantic declaration symbols, scopes, declarations, or
  navigation targets are created from begin-action syntax.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README and docs.
