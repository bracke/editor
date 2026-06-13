Editor Phase 579 pass 270

This pass extends parser-owned Ada statement-awareness metadata for selective accept syntax.

Implemented:
- Added Statement_Accept_Alternative to Editor.Ada_Language_Model.Statement_Kind.
- Parser now recognizes same-line selective accept alternatives such as:
  - or accept Stop;
  - or accept Flush (Count : Natural) do
  - or accept Family (Index) (Item : Payload);
- Same-line accept alternatives retain base Statement_Accept metadata.
- Existing accept shape metadata is reused for alternatives:
  - Statement_Accept_Body
  - Statement_Accept_With_Profile
  - Statement_Accept_Entry_Family_Index
- Added AUnit coverage in Test_Language_Model_Statement_Awareness.
- Extended phase579_language_validation_check guards.
- Updated README and docs.

Non-goals preserved:
- No Outline rows are created from accept-alternative syntax.
- No semantic declaration symbols are learned from accept alternatives.
- No scopes, declarations, or navigation targets are created from statement syntax.
- This remains bounded statement-awareness metadata, not a full Ada statement AST.
