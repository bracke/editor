Pass 432 — Unknown discriminant part grammar

This pass extends the Ada token-cursor grammar for unknown discriminant
parts.  Ada permits declarations such as:

   type T (<>) is private;
   type Deferred (<>);

The parser now recognizes the compact (<>) syntax as
Production_Unknown_Discriminant_Part under Production_Discriminant_Part,
instead of routing the box token through malformed discriminant specification
recovery.

Updated areas:
- src/core/editor-ada_token_cursor.ads
- src/core/editor-ada_token_cursor.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/language_validation_check.adb
- tools/release_check.adb
- README.md
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md

This is syntax retention only.  It does not implement compiler-grade
completion legality, private/full-view matching, discriminant constraint
legality, freezing rules, or representation legality.
