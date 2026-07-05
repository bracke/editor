# Editor Pass 790

Pass790 deepens requeue statement structural recovery.

Implemented:
- Added Production_Requeue_Terminator.
- Added Production_Requeue_With_Missing_Abort_Recovery_Boundary.
- Requeue statements now retain a requeue-specific terminator marker when the semicolon is visible.
- Malformed `requeue Target with;` forms now retain bounded missing-`abort` recovery metadata instead of only falling through generic statement skipping.
- Added AUnit regression Test_Language_Model_Token_Cursor_Requeue_Recovery_Pass790.
- Updated validation and release guards.

Scope:
- This improves structural grammar coverage and bounded recovery for Ada requeue statements.
- This is not compiler-grade tasking legality checking, requeue target resolution, entry matching, abortability legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
