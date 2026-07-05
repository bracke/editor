pass 254 — alternative action statement awareness

This pass extends parser-owned Ada statement awareness for executable alternatives.

Implemented:
- Added Statement_Alternative_Raise, Statement_Alternative_Return,
  Statement_Alternative_Assignment, and Statement_Alternative_Call to
  Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Mark_Alternative_Action support for simple actions after
  executable alternative arrows, such as:
    when A => Value := 1;
    when B => Deliver (Item);
    when C => return;
    when others => raise Program_Error with "bad";
- Alternative actions retain their base statement metadata where safe:
  Statement_Assignment, Statement_Call, Statement_Return, Statement_Raise, and
  Statement_Raise_With_Message.
- Record variant alternatives remain excluded from executable-statement
  metadata.
- No Outline rows, semantic declaration symbols, scopes, or navigation targets
  are created from alternative action metadata.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README and language documentation.

This remains bounded statement-awareness metadata, not a full statement AST or
expression parser.
