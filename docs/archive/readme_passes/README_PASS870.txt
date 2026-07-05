Editor Pass870
==========================

This pass deepens structural Ada token-cursor coverage for loop body
statement recovery.

Implemented changes:

* Added Production_Loop_Missing_Statement_Recovery_Boundary.
* Updated loop, while-loop, discrete for-loop, and iterator-loop parsing so
  empty loop bodies immediately followed by end loop retain loop-specific
  missing-statement recovery metadata.
* Preserved loop begin, statement-sequence, end-loop, end-name, terminator,
  and following-statement visibility.
* Added AUnit coverage in
  Test_Language_Model_Token_Cursor_Loop_Body_Statement_Recovery_Pass870.

This improves structural grammar coverage for Ada loop statement bodies. It is
not compiler-grade loop legality checking, statement legality checking,
control-flow validation, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.
