Editor pass 272

Implemented another parser-owned statement-awareness pass.

Changes:
- Added Statement_Then_Action to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Mark_Compact_Then_Action_Details.
- Parser now recognizes compact same-line if-then actions such as:
    if Ready then Worker.Deliver (Name => Item); end if;
    if Failed then Status := Error; end if;
    if Done then return Value; end if;
    if Bad then raise Program_Error with "bad"; end if;
- Embedded simple action shape is retained where visible:
    call action metadata,
    call argument/named-association/selected-name metadata,
    assignment metadata,
    return-expression metadata,
    raise/reraise/raise-with-message metadata,
    code-statement metadata where applicable.
- Then-action metadata does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while still remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
