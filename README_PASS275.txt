Editor phase 579 pass 275

Implemented another Ada parser statement-awareness pass.

Changes:
- Added Statement_Loop_Action to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Mark_Compact_Loop_Action_Details.
- Parser now recognizes compact same-line loop-body actions such as:
  * while Ready loop Worker.Deliver (Name => Item); end loop;
  * for I in 1 .. 10 loop Status := I; end loop;
  * loop return Value; end loop;
  * while Bad loop raise Program_Error with "bad"; end loop;
- Embedded loop-body action shape is retained where visible:
  * call metadata
  * call argument / named-association metadata
  * assignment metadata
  * return-expression metadata
  * raise / raise-with-message metadata
  * code-statement metadata where applicable
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from loop-body action syntax.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.
