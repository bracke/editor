Editor Phase 579 pass861 — goto target recovery depth

Pass861 improves structural Ada statement recovery for malformed/in-progress
`goto` statements where the required label name is missing. The token cursor now
records `Production_Goto_Missing_Target_Recovery_Boundary` for forms such as
`goto;` while preserving the existing generic goto recovery marker, semicolon
terminator metadata, and following label/statement visibility.

Regression coverage:
- `Test_Language_Model_Token_Cursor_Goto_Target_Recovery_Pass861`

This is parser/token-cursor metadata only. It is not compiler-grade goto
legality checking, label resolution, duplicate-label validation, visibility
analysis, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.
