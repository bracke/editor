pass 291

This pass extends parser-owned Ada statement awareness for compact conditional entry-call select else fallbacks.

Implemented:
- Added select-specific else fallback action metadata:
  - Statement_Select_Else_Null
  - Statement_Select_Else_Return
  - Statement_Select_Else_Raise
  - Statement_Select_Else_Assignment
  - Statement_Select_Else_Call
  - Statement_Select_Else_Code
- The parser now trims trailing compact `end select;` text before classifying the same-line else fallback action.
- Compact forms such as:
  - select Server.Request; else null; end select;
  - select Server.Request; else Status := Timeout; end select;
  - select Server.Request; else return; end select;
  - select Server.Request; else raise Program_Error with "timeout"; end select;
  - select Server.Request; else Recover (Reason => Timeout); end select;
  - select Server.Request; else Instruction'(Opcode => 16#90#); end select;
  retain select-specific bounded statement metadata.
- Existing base action metadata is preserved where applicable.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from this syntax.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check.
- Updated README and language-feature documentation.
