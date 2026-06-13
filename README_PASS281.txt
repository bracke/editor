Editor phase 579 pass 281

This pass extends the Ada declaration parser's bounded statement-awareness metadata for compact conditional entry-call select statements with same-line else fallbacks.

Implemented:
- Added Statement_Select_Else_Action to Editor.Ada_Language_Model.Statement_Kind.
- The parser now recognizes forms such as:
    select Server.Request (Item => Payload); else Recover (Reason => Timeout); end select;
- The select opener keeps Statement_Select and Statement_Select_Entry_Call metadata.
- The same-line else fallback keeps Statement_Select_Else_Action plus the embedded action shape where visible.
- Fallback calls retain ordinary call, selected-name, argument-list, and named-association metadata.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from this statement syntax.

Updated:
- AUnit statement-awareness coverage.
- tools/phase579_language_validation_check.adb guards.
- README.md.
- docs/outline.md.
- docs/syntax_colouring.md.
- docs/release/RELEASE_CHECKLIST.md.
