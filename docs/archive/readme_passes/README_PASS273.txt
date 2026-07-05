Pass 273 - Compact same-line else-action statement metadata

Implemented parser-owned Statement_Else_Action metadata for compact generated Ada conditionals with an action between `else` and the following semicolon.  The parser now preserves visible else-action shape for call, named-association call, assignment, return-expression, raise-with-message, and code-statement actions without creating Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.

Updated files include:
- src/core/editor-ada_language_model.ads
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/language_validation_check.adb
- README.md
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
