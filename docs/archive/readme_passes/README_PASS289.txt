Editor IDE-grade Outline/Semantic Language Model - Pass 289

Implemented parser-owned pragma statement awareness.

Changes:
- Added Statement_Pragma and Statement_Pragma_With_Arguments to Editor.Ada_Language_Model.Statement_Kind.
- Added Mark_Pragma_Details in Editor.Ada_Declaration_Parser.
- Parser now records executable pragma statements such as pragma Assert (Ready);.
- Parser now records pragma actions after executable alternatives such as when A => pragma Assert (Ready);.
- Pragmas with parenthesized argument lists retain Statement_Pragma_With_Arguments.
- Pragma names and arguments are not learned as Outline rows, semantic symbols, scopes, declarations, or navigation targets.
- Added AUnit statement-awareness coverage.
- Extended language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while remaining bounded statement-awareness metadata rather than a full Ada statement/name/expression AST.
