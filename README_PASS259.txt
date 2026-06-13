Editor Phase 579 pass 259

This pass extends parser-owned Ada statement awareness for named loop terminators.

Implemented:
- Added Statement_End_Named_Loop to Editor.Ada_Language_Model.Statement_Kind.
- Parser now records named loop terminators such as `end loop Outer;`.
- Named loop terminators still retain the base Statement_End_Loop metadata.
- Ordinary `end loop;` remains only the base structured loop terminator.
- Added AUnit coverage in Test_Language_Model_Statement_Awareness using the existing named-loop fixture.
- Extended phase579_language_validation_check guards.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This remains bounded parser metadata only. It does not create Outline rows, semantic declaration symbols, scopes, or navigation targets, and it is not a full statement AST.
