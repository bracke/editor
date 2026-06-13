Editor Phase 579 Pass860 — Assignment expression recovery depth

Scope

* Adds assignment-statement-specific recovery metadata for malformed Ada
  assignments where the `:=` token is present but the right-hand expression is
  missing.
* New token-cursor production:
  `Production_Assignment_Missing_Expression_Recovery_Boundary`.
* Adds AUnit regression:
  `Test_Language_Model_Token_Cursor_Assignment_Expression_Recovery_Pass860`.

Behavior

* `X :=;` records a bounded assignment missing-expression recovery boundary.
* A later well-formed assignment such as `X := 1;` still records
  `Production_Assignment_Expression`.
* Recovery leaves following statements visible to outline, diagnostics, and
  semantic-colouring consumers.

Non-goals

This pass improves structural grammar recovery only. It is not compiler-grade
assignment legality checking, left-hand-side legality checking, expression type
checking, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.
