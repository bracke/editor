Editor  IDE-grade outline/semantic language model pass424

Parser-completeness focus: exception-handler choice grammar.

Changes:
- Added Production_Exception_Choice_Parameter, Production_Exception_Choice_List, and Production_Exception_Choice to Editor.Ada_Token_Cursor.
- Extended when-alternative parsing so handlers with a choice parameter, such as `when Failure : Constraint_Error | Program_Error =>`, retain the choice parameter as a defining name and retain each listed exception choice structurally.
- Preserved the handler statement sequence after `=>` while keeping ordinary case alternatives on the existing discrete-choice path.
- Added AUnit coverage in Test_Language_Model_Token_Cursor_Exception_Handler_Grammar_Completeness.
- Updated validation/release guards and docs.

This is syntactic grammar retention only. It does not perform compiler-grade exception identity, handler matching, propagation, or runtime exception semantics.
