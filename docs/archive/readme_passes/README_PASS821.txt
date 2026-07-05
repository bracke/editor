Pass821 - Call and entry-call actual delimiter and recovery depth

Pass821 deepens Ada call and entry-call actual-list metadata. Procedure-call and entry-call statements with actual parts now retain explicit actual-list open/close delimiter productions, comma separator productions between top-level actual associations, and a bounded missing-close recovery production when an in-progress actual list reaches a semicolon before its closing parenthesis. Existing call target, selected target, dispatching-prefix, indexed/actual ambiguity, actual-association, entry-call target, entry-name, entry-family index, call terminator, and missing-terminator metadata remains intact.

Changed:
- Added call actual-list delimiter productions for opening parenthesis, closing parenthesis, comma separators, and missing-close recovery.
- Added matching entry-call actual-list delimiter productions so selected entry-call and procedure-call ambiguity metadata can colour/navigate actual parts consistently.
- Added bounded recovery for malformed/in-progress call actual lists without consuming the following statement.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Call_Actual_Delimiters_Pass821`.
- Updated parser coverage docs, syntax-colouring notes, release checklist, and  validation guard markers.

This improves structural grammar coverage for Ada call and entry-call actual-list delimiters, separators, and missing-close recovery. It is not compiler-grade overload resolution, callable-entity legality checking, parameter-mode conformance, named/positional actual legality, visibility analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
