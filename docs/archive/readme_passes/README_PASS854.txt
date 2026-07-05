Pass854 - Select guard missing-condition recovery depth

This pass improves token-cursor structural grammar coverage for Ada select
alternative guards.

Changes:
- Added Production_Select_Guard_Missing_Condition_Recovery_Boundary.
- Updated select guard parsing so well-formed guards keep condition metadata.
- Updated malformed guards such as `when =>` to record bounded
  missing-condition recovery while preserving the following guard arrow.
- Added regression coverage for guarded select alternatives with both
  well-formed and missing-condition guards.

Regression:
- Test_Language_Model_Token_Cursor_Select_Guard_Condition_Recovery_Pass854

Scope:
This improves structural grammar coverage for Ada select guard recovery. It is
not compiler-grade select-statement legality checking, guard condition type
checking, tasking legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, or dirty-state mutation.
