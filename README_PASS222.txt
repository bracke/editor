Phase 579 pass 222

This pass adds bounded Ada access-mode declaration metadata to the parser-owned
language model.

Implemented:
- Added Has_Access_All_Metadata and Has_Access_Constant_Metadata to
  Editor.Ada_Language_Model.Declaration_Flags.
- Included those flags in deterministic symbol fingerprints.
- Added parser token-pair detection for adjacent access mode forms:
  access all
  access constant
- Retained the metadata on access type/object/formal declarations without
  creating standalone Outline rows or semantic symbols for all/constant.
- Updated Outline details to display access-all and access-constant metadata.
- Added Test_Language_Model_Access_Mode_Metadata.
- Extended phase579_language_validation_check.
- Updated README and Phase 579 docs/release checklist.

No Python or shell scripts were added.
