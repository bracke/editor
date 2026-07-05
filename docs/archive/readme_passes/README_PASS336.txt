pass 336

This pass extends the token-cursor Ada grammar layer with broader statement production coverage.

Implemented:
- Added token-cursor production kinds for statement-sequence details, elsif/else parts, case alternatives, select alternatives, loop-parameter specifications, extended return statements, null/exit/goto/delay/requeue/abort statements, exception-handler sections, and entry/call actual-part statements.
- Extended token-cursor parsing so statement headers consume relevant expression/header tokens and record expected recovery points where required.
- Added AUnit coverage for the new token-cursor statement grammar productions.
- Extended language_validation_check guards.
- Updated README, outline docs, syntax-colouring docs, and release checklist.

Validation performed in this environment:
- Output archive validates with unzip -t.
- Node_Kind and Production_Kind enumerator lists were checked for duplicate names.
- No .py, .pyc, or .sh files are present in the project tree.
