Editor Pass868 — Case alternative missing-statement recovery depth

This pass improves structural token-cursor coverage for Ada case statement
alternatives whose choice arrow is present but whose statement sequence is
missing or still being typed.

Implemented:

* Added `Production_Case_Alternative_Missing_Statement_Recovery_Boundary`.
* Updated case alternative parsing so malformed/in-progress alternatives such
  as `when 1 =>` followed directly by another `when` retain case-specific
  missing-statement recovery metadata.
* Preserved choice-arrow, case alternative, following alternative, `end case`,
  and following-statement visibility after recovery.
* Added AUnit coverage in
  `Test_Language_Model_Token_Cursor_Case_Alternative_Statement_Recovery_Pass868`.
* Updated parser coverage, semantic-colouring notes, release checklist, and the
   language validation guard.

This is structural grammar coverage only. It is not compiler-grade case-choice
coverage checking, statement legality checking, control-flow validation,
overload resolution, compiler invocation, LSP integration, render-side parsing,
or dirty-state mutation.
