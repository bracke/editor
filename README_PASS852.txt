### Pass852 - Requeue statement missing-terminator recovery depth

Pass852 improves structural grammar coverage for Ada `requeue` statements by adding dedicated missing-terminator recovery metadata.

Changed:
- Added `Production_Requeue_Missing_Terminator_Recovery_Boundary`.
- Updated requeue statement parsing so well-formed `requeue Step with abort;` still records target, `with abort`, and terminator metadata.
- Updated malformed/in-progress `requeue Step with abort` before an enclosing `end` to record bounded missing-terminator recovery instead of falling through as generic statement loss.
- Preserved enclosing accept/block end markers and following statement visibility.
- Added `Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery_Pass852`.
- Updated README, parser coverage matrix, syntax-colouring notes, release checklist, and validation guard markers.

This improves structural grammar coverage for Ada requeue statement completion. It is not compiler-grade requeue legality checking, entry-family validation, select/accept context validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
