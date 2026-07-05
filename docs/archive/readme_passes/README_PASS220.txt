pass 220

This pass adds bounded Ada entry-barrier metadata to the parser-owned language model.

Changes:
- Added Has_Entry_Barrier_Metadata to Declaration_Flags.
- Included entry-barrier metadata in deterministic language-model fingerprints.
- Updated Editor.Ada_Declaration_Parser to detect entry bodies with when barriers.
- Updated Outline detail projection to expose entry-barrier metadata.
- Added Test_Language_Model_Entry_Barrier_Metadata.
- Extended language_validation_check for model/parser/test markers.
- Updated README and docs.

The barrier expression remains non-declarative: no Outline rows, symbols, or semantic identifiers are learned from the barrier condition.
