pass 426 — exit/goto transfer-statement grammar

Implemented in this pass:

- Added token-cursor productions:
  - Production_Exit_Target
  - Production_Exit_When_Condition
  - Production_Goto_Target
- Extended exit-statement parsing so it now structurally retains:
  - optional loop-name target: exit Main;
  - optional when condition: exit when Done;
  - combined target and condition: exit Main when Done;
- Extended goto-statement parsing so it now structurally retains target label names:
  - goto Finished;
- Added AUnit coverage:
  - Test_Language_Model_Token_Cursor_Exit_Goto_Grammar_Completeness
- Updated validation guards, release guard comments, README/docs, release checklist.

This is syntactic grammar retention only. It does not perform compiler-grade
label visibility, loop-name legality, transfer legality, reachability analysis,
or control-flow validation.
