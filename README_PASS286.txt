Phase 579 pass 286 — compact declare-block statement action metadata

This pass continues closing parser gap nr 1 using bounded parser-owned statement awareness.

Implemented:
- Added Statement_Declare_Action to Editor.Ada_Language_Model.Statement_Kind.
- Added Mark_Compact_Declare_Action_Details in Editor.Ada_Declaration_Parser.
- Compact/generated declare blocks such as:

    declare Local : Natural := 0; begin Worker.Deliver (Name => Item); end;
    declare Local : Natural := 0; begin Status := Ready; end;
    declare Local : Natural := 0; begin return Value; end;
    declare Local : Natural := 0; begin raise Program_Error with "bad"; end;

  now retain explicit compact declare-action metadata.
- Embedded begin-action/simple-action shape remains retained through the existing compact begin-action path.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from compact declare action syntax.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This remains metadata-level statement recognition, not a full Ada statement/name/expression AST.
