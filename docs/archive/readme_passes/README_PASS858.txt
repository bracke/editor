# Editor Pass858 — Raise-statement message recovery depth

Pass858 improves structural grammar coverage for Ada raise statements whose
optional `with` message keyword is present but the message expression is
missing.

## Changed

* Added token-cursor production:
  * `Production_Raise_Statement_Message_Recovery_Boundary`
* Updated raise-statement parsing so malformed/in-progress forms such as
  `raise Constraint_Error with;` retain statement-specific bounded missing-
  message recovery metadata.
* Preserved existing shared raise-message recovery metadata, raise-statement
  target metadata, well-formed message-expression metadata, terminators, and
  following-statement visibility.
* Added AUnit regression:
  * `Test_Language_Model_Token_Cursor_Raise_Statement_Message_Recovery_Pass858`

This remains structural parser/token-cursor metadata only. It is not
compiler-grade raise-statement legality checking, exception visibility
analysis, message type checking, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.
