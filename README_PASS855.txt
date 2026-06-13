# Editor Phase 579 Pass855 — Abort target recovery depth

Pass855 improves structural grammar coverage for Ada `abort` statements by adding abort-target-specific missing-target recovery metadata.

Changes:

- Adds `Production_Abort_Missing_Target_Recovery_Boundary`.
- Records target-specific recovery for `abort;` and trailing-comma/in-progress target lists such as `abort Worker, ;`.
- Preserves existing abort statement, target-list, target-name, target-separator, terminator, and broader abort recovery metadata.
- Adds AUnit coverage in `Test_Language_Model_Token_Cursor_Abort_Target_Recovery_Pass855`.

Scope: this is parser/token-cursor structural metadata only. It is not compiler-grade abort statement legality checking, task-name resolution, tasking legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
