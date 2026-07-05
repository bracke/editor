Editor pass857 — raise-expression message recovery depth

This pass adds expression-specific recovery metadata for Ada raise expressions
whose optional with-message clause is present but lacks its message expression.

Implemented:
- Production_Raise_Expression_Message_Recovery_Boundary.
- Raise-expression parser tagging for malformed forms such as:
    (if Ready then raise Constraint_Error with else False)
- AUnit regression:
    Test_Language_Model_Token_Cursor_Raise_Expression_Message_Recovery_Pass857

Scope:
This improves structural grammar coverage for Ada raise-expression with-message
recovery.  It is not compiler-grade raise-expression legality checking,
exception visibility analysis, message type checking, overload resolution,
compiler invocation, LSP integration, render-side parsing, or dirty-state
mutation.
