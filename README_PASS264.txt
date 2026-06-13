Editor Phase 579 Pass 264

This pass extends parser-owned Ada statement awareness for accept statements.

Implemented:
- Added Statement_Accept_With_Profile.
- Added Statement_Accept_Entry_Family_Index.
- Added parser-side Mark_Accept_Details.
- Accept statements with colon-bearing parameter profiles now retain explicit profile metadata.
- Accept statements with entry-family/index parenthesized targets now retain explicit entry-family metadata.
- Existing accept and accept-body metadata is preserved.
- Added AUnit coverage in Test_Language_Model_Statement_Awareness.
- Extended phase579_language_validation_check.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

The metadata remains bounded parser fingerprint data only. It does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.
