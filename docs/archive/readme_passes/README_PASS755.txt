# Editor — pass755

This pass deepens task/protected body internal grammar coverage in the Ada token cursor.

## Changed

* Added bounded token-cursor productions for task body internals:
  * `Production_Task_Body_Declarative_Item_Start`
  * `Production_Task_Body_Begin_Keyword`
  * `Production_Task_Body_End_Keyword`
  * `Production_Task_Body_Recovery_Boundary`
* Added bounded token-cursor productions for protected body internals:
  * `Production_Protected_Body_Operation_Begin_Keyword`
  * `Production_Protected_Body_Operation_End_Keyword`
  * `Production_Protected_Body_Recovery_Boundary`
* Task bodies now retain explicit declarative-item start, `begin`, statement-sequence, exception-part, and `end` metadata.
* Protected bodies now retain explicit operation-body `begin`/`end` metadata for procedure/function/entry bodies.
* Misplaced `private` inside a protected body now leaves a bounded recovery marker rather than becoming silent parser drift.
* Extended AUnit coverage in `Test_Language_Model_Token_Cursor_Task_Protected_Body_Internal_Grammar_Completeness`.
* Updated validation guards and documentation.

## Non-goals

This is structural grammar metadata only. It is not compiler-grade task/protected body legality checking, protected-operation conformance checking, entry-barrier semantic validation, synchronization analysis, or tasking control-flow analysis.
