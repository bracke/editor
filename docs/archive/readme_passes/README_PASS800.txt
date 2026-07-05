# Editor — Pass800

Pass800 deepens Ada call-statement terminator/recovery metadata.

Changed:

- Added token-cursor productions:
  - `Production_Call_Terminator`
  - `Production_Call_Missing_Terminator_Recovery_Boundary`
- Well-formed call statements now retain call-specific semicolon metadata:
  ```ada
  Run (1);
  ```
- Malformed or in-progress call statements that reach a body/select boundary without a visible semicolon now emit bounded recovery metadata:
  ```ada
  Worker.Start (2)
  end Call_Terminator_Recovery;
  ```
- Preserved existing call/entry-call metadata:
  - `Production_Call_Statement`
  - `Production_Call_Target`
  - selected/dispatching/indexed call target metadata
  - `Production_Call_Actual_Part`
  - `Production_Call_Actual_List`
  - `Production_Call_Actual_Association`
  - entry-call ambiguity and select-entry-call metadata
- Added AUnit regression:
  - `Test_Language_Model_Token_Cursor_Call_Terminator_Recovery_Pass800`
- Updated validation/release guards.

This improves structural grammar coverage and bounded recovery for Ada call statements. It is not compiler-grade callable resolution, parameter profile matching, entry-call legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
