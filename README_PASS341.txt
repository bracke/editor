Pass 341 — token-cursor concurrent grammar completeness

This pass extends the Ada token-cursor grammar coverage added in earlier passes.
It adds first-class grammar productions for task definitions, protected definitions,
entry-family definitions, and entry-body barriers. Task/protected declarations with
an `is` part no longer skip their nested entries and protected operations while
scanning to the next semicolon; the cursor advances to the definition body and
continues parsing contained declarations structurally.

Key source changes:
- src/core/editor-ada_token_cursor.ads
- src/core/editor-ada_token_cursor.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/phase579_language_validation_check.adb
- tools/release_check.adb

Validation intent:
- Token-cursor grammar must retain task/protected definition productions.
- Entry declarations inside task/protected definitions must remain visible.
- Entry family definitions and entry barriers must be recognized structurally.
- No Python or shell scripts are introduced.
