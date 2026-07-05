pass 436 — aspect-mark token-cursor grammar

This pass extends the Ada token-cursor grammar so aspect specifications retain aspect marks explicitly instead of parsing each association head as a generic expression.

Implemented:
- Added Production_Aspect_Mark.
- Added Production_Classwide_Aspect_Mark.
- Added Parse_Aspect_Mark and routed aspect associations through it.
- Preserved nullary aspects such as `with Preelaborate` without inventing a value expression.
- Preserved class-wide aspect marks such as `Type_Invariant'Class => ...` structurally.
- Added AUnit coverage in Test_Language_Model_Token_Cursor_Aspect_Mark_Grammar_Completeness.
- Updated validation/release guards and documentation notes.

Still intentionally outside this parser pass:
- aspect legality and allowed-aspect placement;
- aspect-definition type checking;
- class-wide aspect inheritance semantics;
- freezing/staticness legality;
- GNAT-equivalent semantic validation.
