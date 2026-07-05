Editor — Pass899

This pass improves structural Ada grammar coverage for entry barriers whose
`when` condition is missing.

Changes:
- Added Production_Entry_Barrier_Missing_Condition_Recovery_Boundary.
- Added Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary.
- Updated entry barrier parsing so `is`, `with`, `begin`, `end`, `or`, `else`,
  `then`, `;`, and end-of-input are treated as recovery boundaries after
  `when`, not as condition expressions.
- Updated protected entry-body scanning so protected-entry-specific barrier
  recovery metadata is retained.
- Added AUnit regression
  Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Recovery_Pass899.
- Updated validation/release/docs markers.

This improves structural grammar coverage for malformed Ada entry barriers. It
is not compiler-grade tasking legality checking, barrier condition type
checking, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state
mutation.
