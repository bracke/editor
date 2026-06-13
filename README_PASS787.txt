Editor Phase 579 pass787 - select guard missing-arrow recovery depth

Changed:
- Added Production_Select_Guard_Missing_Arrow_Recovery_Boundary.
- Select alternatives with a guard condition but missing => now retain guard-specific recovery metadata.
- Preserved Production_Select_Guard, Production_Select_Guard_Condition, and the shared Production_Select_Alternative_Recovery_Boundary.
- Added Test_Language_Model_Token_Cursor_Select_Guard_Missing_Arrow_Pass787.
- Updated validation and release guards.

Scope:
This improves structural grammar recovery for Ada select guards. It is not compiler-grade tasking legality checking, guard-expression legality checking, entry-call matching, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
