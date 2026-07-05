Editor  IDE-grade Outline/Semantic language-model pass 290

Implemented another parser-owned statement-awareness pass.

Changes:
- Added Statement_Alternative_Pragma to Editor.Ada_Language_Model.Statement_Kind.
- Updated the Ada declaration parser so pragma actions after executable alternatives stamp explicit alternative-pragma metadata.
- `when A => pragma Assert (Ready);` now retains Statement_Pragma, Statement_Pragma_With_Arguments where applicable, and Statement_Alternative_Pragma.
- Ordinary executable pragmas such as `pragma Inspection_Point;` remain ordinary Statement_Pragma metadata only.
- Pragma names and arguments are still not learned as Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
