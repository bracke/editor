Pass 258 parser increment

Implemented parser-owned Ada for-loop iteration-scheme statement awareness.

Changes:
- Added Statement_For_In_Loop.
- Added Statement_For_Of_Loop.
- Added Statement_For_Reverse_Loop.
- Parser now records discrete for-in loops, container for-of iterator loops, and reverse discrete loops as explicit statement metadata while retaining Statement_For_Loop.
- Named for loops still classify through the same underlying loop path after named-statement prefix stripping.
- No Outline rows, semantic symbols, scopes, declarations, or navigation targets are created from this metadata.
- Added AUnit coverage in Test_Language_Model_Statement_Awareness.
- Extended language_validation_check guards.
- Updated README, outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 using bounded statement-awareness metadata; it is still not a full Ada statement AST or expression parser.
