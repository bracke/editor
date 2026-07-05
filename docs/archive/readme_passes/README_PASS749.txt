# Editor — pass749

This pass deepens structural Ada token-cursor coverage for abort-statement target lists.

## Changes

* Added abort target-shape productions:
  * `Production_Abort_Selected_Target`
  * `Production_Abort_Indexed_Target`
  * `Production_Abort_Dereferenced_Target`
  * `Production_Abort_Target_Separator`
  * `Production_Abort_Recovery_Boundary`
* `abort` statements now retain explicit metadata for:
  * selected task-name targets such as `Controller.Current`
  * indexed task-name targets such as `Pool.Tasks (Index)`
  * explicit dereference targets such as `Controller.Current.all`
  * comma separators between abort targets
  * bounded recovery when the target list is empty or prematurely terminated
* Extended AUnit coverage in `Test_Language_Model_Token_Cursor_Abort_Statement_Grammar_Completeness`.
* Updated validation guards and parser coverage documentation.

## Non-goals

This improves structural grammar coverage for Ada abort-statement target lists. It is not compiler-grade tasking legality checking, task object resolution, abortability validation, accessibility checking, or control-flow analysis.
