Editor Phase 579 Pass862 — Raise-statement missing exception-name recovery depth

This pass improves structural Ada grammar coverage for raise statements whose optional
message introducer is present before an exception name has been typed.

Changes:
- Added Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary.
- Updated raise-statement parsing so `raise with "message";` records missing exception-name recovery instead of tagging `with` as the exception name.
- Preserved with-message keyword and message-expression metadata so recovery stays useful for outline, diagnostics, and semantic colouring.
- Added AUnit coverage in Test_Language_Model_Token_Cursor_Raise_Statement_Exception_Name_Recovery_Pass862.
- Updated validation/release guard markers and parser coverage documentation.

This improves structural grammar coverage only. It is not compiler-grade raise-statement legality checking, exception visibility analysis, message type checking, overload resolution, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.
