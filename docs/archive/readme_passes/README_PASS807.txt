Editor pass807 — task/protected body end terminator recovery depth

Implemented:
- Added token-cursor productions:
  - Production_Task_Body_End_Name
  - Production_Task_Body_End_Terminator
  - Production_Task_Body_Missing_End_Terminator_Recovery_Boundary
  - Production_Protected_Body_End_Keyword
  - Production_Protected_Body_End_Name
  - Production_Protected_Body_End_Terminator
  - Production_Protected_Body_Missing_End_Terminator_Recovery_Boundary
- Task body endings now retain optional end-name and semicolon terminator metadata.
- Task body endings without a visible semicolon now retain bounded task-body-specific recovery metadata.
- Outer protected body endings now retain protected-body-specific end-keyword, optional end-name, semicolon terminator, and missing-terminator recovery metadata.
- Protected operation end-keyword metadata remains preserved.
- Added AUnit regression:
  - Test_Language_Model_Token_Cursor_Concurrent_Body_End_Terminator_Recovery_Pass807
- Updated validation/release guards and parser coverage documentation.

Scope:
This improves structural grammar coverage and bounded recovery for Ada task and protected body endings. It is not compiler-grade tasking legality checking, protected-operation conformance checking, body/spec conformance checking, end-name matching, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
