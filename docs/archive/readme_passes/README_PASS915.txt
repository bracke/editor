Editor — Pass915
==========================

This pass improves structural Ada grammar coverage for malformed raise-with-message
statements at reserved statement-sequence boundaries.

Changed:

* Added Production_Raise_Message_Reserved_Boundary_Recovery_Boundary.
* Refined raise-statement parsing so `raise Program_Error with else;` records
  raise-message-specific recovery instead of treating `else` as a message
  expression.
* Preserved broader raise statement, raise-with-message keyword, valid message
  expression, raise terminator, and generic recovery metadata.
* Added AUnit regression:
  Test_Language_Model_Token_Cursor_Raise_Message_Reserved_Boundary_Recovery_Pass915.
* Updated validation guard comments, parser coverage docs, syntax-colouring notes,
  release checklist, and README.

Scope:

This improves structural grammar coverage for malformed Ada raise-with-message
expressions. It is not compiler-grade message-expression legality checking,
exception-name legality checking, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.
