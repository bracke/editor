Editor Phase 579 IDE-grade Outline/Semantic Language Model - Pass 267

This pass expands parser-owned Ada statement awareness for raise statements.

Implemented:
- Added Statement_Raise_Reraise to distinguish bare reraises such as `raise;`.
- Added Statement_Raise_Exception_Name to distinguish explicit named raises such as `raise Constraint_Error;`.
- Kept Statement_Raise_With_Message for message raises such as `raise Program_Error with "bad";`.
- Centralized raise statement shape classification in Mark_Raise_Details.
- Applied the same raise-form metadata to executable alternative actions such as `when others => raise;`.
- Added AUnit coverage in Test_Language_Model_Statement_Awareness.
- Extended phase579_language_validation_check guards.
- Updated README and docs.

The new metadata is parser/fingerprint state only.  It does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.
